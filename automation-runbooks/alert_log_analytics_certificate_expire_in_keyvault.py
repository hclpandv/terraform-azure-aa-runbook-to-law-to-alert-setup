#!/usr/bin/env python3

import os
from datetime import datetime, timezone, timedelta
from azure.identity import ManagedIdentityCredential
from azure.keyvault.certificates import CertificateClient
from azure.monitor.ingestion import LogsIngestionClient
from azure.core.exceptions import AzureError, HttpResponseError

# Configuration constants
SUBSCRIPTION_ID = "b4bd79bb-2081-4f1e-8cc4-5c600d3bafc2"
VAULT_URL = "https://vikivault01.vault.azure.net/"
EXPIRY_THRESHOLD_DAYS = 29

# read email secrets from automation accounts variables
endpoint_uri = "https://dce01-dt11.westeurope-1.ingest.monitor.azure.com" # logs ingestion endpoint of the DCR
dcr_immutableid = "dcr-3fbaf3b21cb54db99648616fa4ce402c" # immutableId property of the Data Collection Rule
stream_name = "Custom-AScertificateExpiring_CL" #name of the stream in the DCR that represents the destination table

def get_certificate_expiry_status(vault_url, credential):
    try:
        certificate_client = CertificateClient(vault_url=vault_url, credential=credential)
        certificates = certificate_client.list_properties_of_certificates()
    except AzureError as e:
        print(f"Error: Failed to list certificates: {e}")
        return []

    expired_certificates = []
    now = datetime.now(timezone.utc)

    for certificate in certificates:
        certificate_name = certificate.name
        certificate_expiry = certificate.expires_on

        if not certificate_expiry:
            print(f"Warning: Certificate {certificate_name} does not have an expiry date.")
            continue

        difference = certificate_expiry - now
        if difference.days < EXPIRY_THRESHOLD_DAYS:
            expiry_date_str = certificate_expiry.date().isoformat()
            expired_certificates.append(f"Certificate {certificate_name} expires on {expiry_date_str}")
            print(f"Info: Certificate {certificate_name} is expiring soon: {expiry_date_str}")

    return expired_certificates

def alert_to_log_analytics(expired_certificates, log_ingestion_client):
    body = [{
        "TimeGenerated": "2023-03-15T15:04:48.423211Z",
        "ExpiryDetails": f"Few certificates are expiring in less than {EXPIRY_THRESHOLD_DAYS} days",
        "ExpiringCertificates": expired_certificates,
        "Severitylevel": "High" if expired_certificates else "Low"
    }]


    try:
        log_ingestion_client.upload(rule_id=dcr_immutableid, stream_name=stream_name, logs=body)
    except HttpResponseError as e:
        print(f"Upload failed: {e}")

def main():
    credential = ManagedIdentityCredential()
    expired_certificates = get_certificate_expiry_status(VAULT_URL, credential)
    log_ingestion_client = LogsIngestionClient(endpoint=endpoint_uri, credential=credential, logging_enable=True)
    alert_to_log_analytics(expired_certificates, log_ingestion_client)

if __name__ == "__main__":
    main()