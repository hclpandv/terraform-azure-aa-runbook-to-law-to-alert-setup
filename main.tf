#---------------------------------------
# Resource group
#---------------------------------------
resource "azurerm_resource_group" "rg_1" {
  name     = "rg-we-viki-github-deployments01"
  location = "westeurope"
}

#---------------------------------------
# Azure automation account
#---------------------------------------
module "automation_account_01" {
  source                                 = "./local_modules/azure_paas_automation_account"
  automation_account_location            = azurerm_resource_group.rg_1.location
  automation_account_name                = "aa-we-vikitest-1"
  automation_account_resource_group_name = azurerm_resource_group.rg_1.name
  python3_shared_packages                = {
    azure_identity = {
      content_uri     = "https://files.pythonhosted.org/packages/49/83/a777861351e7b99e7c84ff3b36bab35e87b6e5d36e50b6905e148c696515/azure_identity-1.17.1-py3-none-any.whl"
      content_version = "1.17.1"
    }
    azure_common = {
      content_uri     = "https://files.pythonhosted.org/packages/62/55/7f118b9c1b23ec15ca05d15a578d8207aa1706bc6f7c87218efffbbf875d/azure_common-1.1.28-py2.py3-none-any.whl"
      content_version = "1.1.28"
    }
    azure_core = {
      content_uri     = "https://files.pythonhosted.org/packages/ef/d7/69d53f37733f8cb844862781767aef432ff3152bc9b9864dc98c7e286ce9/azure_core-1.30.2-py3-none-any.whl"
      content_version = "1.30.2"
    }
    azure_keyvault_certificates = {
      content_uri     = "https://files.pythonhosted.org/packages/20/f0/e5404eb87d20a6937a6672b070f820b5b6e81050723eea8494b04e3699df/azure_keyvault_certificates-4.8.0-py3-none-any.whl"
      content_version = "4.8.0"
    }
    azure_communication_email = {
      content_uri     = "https://files.pythonhosted.org/packages/43/6e/0d73cadbcc572db66284fea3ca6a84caf5799740bdb54454175e68fc65a4/azure_communication_email-1.0.0-py3-none-any.whl"
      content_version = "1.0.0"
    }
  }
  system_assigned_identity_enabled       = true
  automation_runbooks_config = {
    keyvault_certs_expiration_alert = {
      runbook_type       = "Python3"
      description        = "Monitor public certificates expiration in a keyvault"
      file_content       = file("${path.module}/automation-runbooks/alert_log_analytics_certificate_expire_in_keyvault.py")
      schedule_frequency = "Daily"
    }
  }
  shared_variables = {
    azure_sender_domain = {
      value = "testval"
    }
  }

  automation_account_tags = {
    deployment_method = "github-actions"
  }
}

#---------------------------------------
# Log analytics workspace
#---------------------------------------
resource "azurerm_log_analytics_workspace" "law_01" {
  name                = "law-we-monitor-01"
  location            = azurerm_resource_group.rg_1.location
  resource_group_name = azurerm_resource_group.rg_1.name
  sku                 = "PerGB2018"
  #retention_in_days   = 10
}

#------------------------------------------------------------------
# Deploy DCR, DCE and alert on an existing log analytics workspace
#------------------------------------------------------------------
resource "azurerm_monitor_data_collection_endpoint" "instance_01" {
  name                = "aa-we-vikitest-1-dce"
  location            = azurerm_resource_group.rg_1.location
  resource_group_name = azurerm_resource_group.rg_1.name
  description         = "Data collection endpoint for ingesting custom logs from python script"
}

resource "azurerm_monitor_data_collection_rule" "example" {
  name                        = "aa-we-vikitest-1-dcr"
  resource_group_name         = azurerm_resource_group.rg_1.name
  location                    = azurerm_resource_group.rg_1.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.instance_01.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law_01.id
      name                  = "aa-runbook-custom-log"
    }
  }
  
  data_flow {
    streams       = ["Custom-CertificateExpiring_CL"]
    destinations  = ["aa-runbook-custom-log"]
    output_stream = "Microsoft-Syslog"
    transform_kql = "source"
  }

  stream_declaration {
    stream_name = "Custom-CertificateExpiring_CL"
    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "ExpiryDetails"
      type = "string"
    }
    column {
      name = "ExpiringCertificates"
      type = "string"
    }
    column {
      name = "Severitylevel"
      type = "string"
    }
  }

  identity {
    type         = "SystemAssigned"
    # identity_ids = [azurerm_user_assigned_identity.example.id]
  }

  description = "data collection rule example"
  tags = {
    foo = "bar"
  }
}