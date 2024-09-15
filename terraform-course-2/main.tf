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

resource "azurerm_resource_group" "app-rg" {
  name     = "app-rg"
  location = "North Europe"

  tags = {
    environment = "course-2"
  }
}

resource "azurerm_storage_account" "terraformstoreourse2" {
    name                     = "terraformstoreourse2"
    resource_group_name      = azurerm_resource_group.app-rg.name
    location                 = azurerm_resource_group.app-rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = {
        environment = "course-2"
    }
}