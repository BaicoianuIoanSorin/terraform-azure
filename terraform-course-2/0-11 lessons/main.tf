terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "storage_account_name" {
  type        = string
  description = "Please enter the storage account name"
  # using default, you won't be asked to enter the value when applying changes
  default = "terraformstoreourse2"
}

locals {
  resource_group = "app-rg"
  location       = "North Europe"
}

resource "azurerm_resource_group" "app-rg" {
  name     = local.resource_group
  location = local.location

  tags = {
    environment = "course-2"
  }
}

resource "azurerm_storage_account" "terraformstoreourse2" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.app-rg.name
  location                 = azurerm_resource_group.app-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true

  depends_on = [azurerm_resource_group.app-rg]

  tags = {
    environment = "course-2"
  }
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.terraformstoreourse2.name
  container_access_type = "blob"

  depends_on = [azurerm_storage_account.terraformstoreourse2]
}

# This is used to upload a local file onto the container
resource "azurerm_storage_blob" "sample" {
  name                   = "sample.txt"
  storage_account_name   = azurerm_storage_account.terraformstoreourse2.name
  storage_container_name = azurerm_storage_container.data.name
  type                   = "Block"
  source                 = "sample.txt"

  # depends on is not actually required in this case as we use the variable azurerm_storage_container.data.name,
  # so terraform already understands that this is a dependency to storage container, but to enforce this dependency, we could add
  # depends_on
  depends_on = [
    azurerm_storage_container.data
  ]
}