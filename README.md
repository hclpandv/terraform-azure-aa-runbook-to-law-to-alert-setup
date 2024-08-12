# terraform-azure-aa-runbook-to-law-to-alert-setup
terraform-azure-aa-runbook-to-law-to-alert-setup


# RBAC permisstion needed

1. `Monitoring Metrics Publisher` role to Automation account MSI on DCR.
2. `Keyvault Reader` role to Automation account MSI on Azure Key vault where Public certficates are stored. 

https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#assign-permissions-to-the-dcr
