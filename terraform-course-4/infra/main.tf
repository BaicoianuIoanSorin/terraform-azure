terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  subscription_id = "9adfbd6b-ffad-4b7c-9c0d-dd74a69d600d"
  features {}
}

variable "prefix" {
  type    = string
  default = "azureterraform"
}

# Define the resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = "eastus"
}

# Define the storage account
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # What are the differences between StorageV1 and StorageV2?
  # https://docs.microsoft.com/en-us/azure/storage/common/storage-account-upgrade?tabs=azure-portal
  account_kind = "StorageV2" # StorageV2 is used for general purpose v2 accounts

  static_website {
    index_document = "index.html"
  }
}

# Add a index.html file to the storage account
resource "azurerm_storage_blob" "blob" {
  name                 = "index.html"
  storage_account_name = azurerm_storage_account.sa.name
  # The name of the container must be "$web" to enable static website hosting
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = "<h1>Ahoy, this is a website deployed using Terraform!</h1>"
}
