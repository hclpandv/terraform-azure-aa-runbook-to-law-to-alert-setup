variable "automation_account_name" { description = "name of the automation account" }
variable "automation_account_location" { description = "azure region of the automation account" }
variable "automation_account_resource_group_name" { description = "resource group name of the automation account" }
variable "automation_account_sku_name" { 
  description = "sku_name of the automation account" 
  type        = string
  default = "Basic"
}
variable "automation_account_tags" { description = "sku_name of the automation account" }

variable "local_authentication_enabled" {
  description = "Should local authentication be enabled for this Automation account?"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Should public network access be enabled for this Automation account?"
  type        = bool
  default     = true
}

variable "system_assigned_identity_enabled" {
  description = "Should the system-assigned identity be enabled for this automation account?"
  type        = bool
  default     = false
}

variable "identity_ids" {
  description = "A list of IDs of managed identities to be assigned to this automation account."
  type        = list(string)
  default     = []
}

variable "python3_shared_packages" {
    description = "Shared python3 packages to be installed on this automation account"
    type = map
    default = {
      azure_identity = {
        content_uri = "https://files.pythonhosted.org/packages/49/83/a777861351e7b99e7c84ff3b36bab35e87b6e5d36e50b6905e148c696515/azure_identity-1.17.1-py3-none-any.whl"
        content_version = "1.17.1"
      }
      azure_common = {
        content_uri = "https://files.pythonhosted.org/packages/62/55/7f118b9c1b23ec15ca05d15a578d8207aa1706bc6f7c87218efffbbf875d/azure_common-1.1.28-py2.py3-none-any.whl"
        content_version = "1.1.28"
      }
      azure_core = {
        content_uri = "https://files.pythonhosted.org/packages/ef/d7/69d53f37733f8cb844862781767aef432ff3152bc9b9864dc98c7e286ce9/azure_core-1.30.2-py3-none-any.whl"
        content_version = "1.30.2"
      }
      azure_keyvault_certificates = {
        content_uri = "https://files.pythonhosted.org/packages/20/f0/e5404eb87d20a6937a6672b070f820b5b6e81050723eea8494b04e3699df/azure_keyvault_certificates-4.8.0-py3-none-any.whl"
        content_version = "4.8.0"
      }
      azure_communication_email = {
        content_uri = "https://files.pythonhosted.org/packages/43/6e/0d73cadbcc572db66284fea3ca6a84caf5799740bdb54454175e68fc65a4/azure_communication_email-1.0.0-py3-none-any.whl"
        content_version = "1.0.0"
      }
    }
}

variable "automation_runbooks_config" {
  type = map(object({ # Key of the map will be used for name
    runbook_type         = string # Graph, GraphPowerShell, GraphPowerShellWorkflow, PowerShellWorkflow, PowerShell, PowerShell72, Python3, Python2 or Script
    description          = string
    file_content         = optional(string)
    publish_content_link = optional(string)
    schedule_frequency   = optional(string) # daily,  weekly, monthly 
  }))
  default = {}
}

variable "shared_variables" {
  type = map(object({ # Key of the map will be used for name
    value      = string
    encrypted  = optional(bool, false)
  }))
  default = {}
}