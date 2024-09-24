resource "random_string" "main" {
  length  = 8
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "rg-ep3-${random_string.main.result}"
  location = var.location
}

resource "azurerm_key_vault" "main" {
  name                = "kv-ep3-${random_string.main.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  #   enabled_for_disk_encryption = true
  tenant_id = data.azurerm_client_config.current.tenant_id
  #   soft_delete_retention_days  = 7
  purge_protection_enabled = false

  sku_name = "standard"
}

resource "azurerm_key_vault_access_policy" "terraform_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "random_string" "keyvault_monitor" {
  length  = 8
  special = false
  upper   = false
}


# need to do EP 1 and 2 First
locals {
  monitor_suffix = "rg-ep3-7cxaifxb"
}

data "azurerm_monitor_log_analytics_workspace" "monitor" {
  name                = storage
  resource_group_name = "rg-ep3-7cxaifxb"
}

data "azurerm_storage_account" "monitor" {
  name                = "storageaccountname"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name                       = "diag-${random_string.keyvault_monitor.result}"
  target_resource_id         = key_vault.main.id
  storage_account_id         = data.azurerm_storage_account.monitor.id
  log_analytics_workspace_id = data.azurerm_monitor_log_analytics_workspace.monitor.id

  log {
    category_group = "audit"

    retention_policy {
      enabled = false
    }
  }
  log {
    category_group = "allLogs"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
