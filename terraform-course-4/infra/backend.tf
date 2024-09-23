# before writing the backend we need a storage account and a container
# We can do that via the Azure CLI
# az login
# create a resource group
# az group create --name terraform-state-rg --location eastus
# create the storage account
# az storage account create --name terraformstateioan --location eastus --resource-group terraform-state-rg
# get the storage account key
# az storage account keys list --resource-group terraform-state-rg --account-name terraformstateioan --query '[0].value' -o tsv
# create the container
# az storage container create --account-name terraformstateioan --name terraformstate --public-access off --account-key {account-key}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstateioan"
    container_name       = "terraformstate"
    key                  = "terraform.tfstate"
  }
}
