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
