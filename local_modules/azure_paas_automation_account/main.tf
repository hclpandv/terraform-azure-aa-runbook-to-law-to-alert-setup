terraform {
  required_version = ">1.3.1"
  required_providers {
    azurerm = ">= 3.33.0"
  }
}

locals {
  # If system_assigned_identity_enabled is true, value is "SystemAssigned".
  # If identity_ids is non-empty, value is "UserAssigned".
  # If system_assigned_identity_enabled is true and identity_ids is non-empty, value is "SystemAssigned, UserAssigned".
  identity_type    = join(", ", compact([var.system_assigned_identity_enabled ? "SystemAssigned" : "", length(var.identity_ids) > 0 ? "UserAssigned" : ""]))
  current_time_utc = timestamp()
  tomorrow         = formatdate("YYYY-MM-DD", timeadd(local.current_time_utc, "24h"))
  tomorrow_7am_utc = "${local.tomorrow}T06:55:00Z"
  # Map of schedules based on frequency
  schedules = {
    "daily"   = azurerm_automation_schedule.shared_daily.name
    "weekly"  = azurerm_automation_schedule.shared_weekly.name
  }
}

#---------------------------------------
# Azure automation account
#---------------------------------------
resource "azurerm_automation_account" "instance" {
  name                = var.automation_account_name
  resource_group_name = var.automation_account_resource_group_name
  location            = var.automation_account_location
  sku_name            = var.automation_account_sku_name

  local_authentication_enabled  = var.local_authentication_enabled
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "identity" {
    for_each = local.identity_type != "" ? [1] : []

    content {
      type         = local.identity_type
      identity_ids = var.identity_ids
    }
  }
  
  tags = var.automation_account_tags
}

# Shared schedules
resource "azurerm_automation_schedule" "shared_weekly" {
  name                    = "shared-weekly"
  resource_group_name     = var.automation_account_resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  timezone                = "Europe/Oslo"
  start_time              = local.tomorrow_7am_utc
  frequency               = "Week"
  interval                = 1
  description             = "Schedule running every week"

  lifecycle {
    ignore_changes = [
      start_time
    ]
  }
}

resource "azurerm_automation_schedule" "shared_daily" {
  name                    = "shared-daily"
  resource_group_name     = var.automation_account_resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  timezone                = "Europe/Oslo"
  start_time              = local.tomorrow_7am_utc
  frequency               = "Day"
  interval                = 1
  description             = "Schedule running every day"

  lifecycle {
    ignore_changes = [
      start_time
    ]
  }
}

# Default set of python3 packages
resource "azurerm_automation_python3_package" "packages" {
  for_each = var.python3_shared_packages

  name                    = each.key
  resource_group_name     = azurerm_automation_account.instance.resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  content_uri             = each.value.content_uri
  content_version         = each.value.content_version
  tags                    = var.automation_account_tags

  depends_on = [ 
    azurerm_automation_account.instance
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Runbooks
resource "azurerm_automation_runbook" "runbooks" {
  for_each = var.automation_runbooks_config != {} ? var.automation_runbooks_config : {}

  name                    = each.key
  location                = var.automation_account_location
  resource_group_name     = var.automation_account_resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  log_verbose             = true
  log_progress            = true
  description             = each.value.description
  runbook_type            = each.value.runbook_type

  content = each.value.file_content != null ? each.value.file_content : null

  dynamic "publish_content_link" {
    for_each = each.value.publish_content_link != null ? [each.value.publish_content_link] : []

    content {
      uri = publish_content_link.value
    }
  }
}

# Shared variables for automation account
resource "azurerm_automation_variable_string" "shared_variables" {
  for_each = var.shared_variables != {} ? var.shared_variables : {} 

  name                    = each.key
  resource_group_name     = var.automation_account_resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
}

# Bind runbook with schedule
resource "azurerm_automation_job_schedule" "runbook_schedules" {
  for_each = {
    for key, value in var.automation_runbooks_config : key => value
    if value.schedule_frequency != null
  }

  resource_group_name     = var.automation_account_resource_group_name
  automation_account_name = azurerm_automation_account.instance.name
  schedule_name           = lookup(local.schedules, lower(each.value.schedule_frequency), null)
  runbook_name            = each.key

  depends_on = [ azurerm_automation_runbook.runbooks ]
}