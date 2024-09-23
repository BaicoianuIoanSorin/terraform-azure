# Define the resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Define the storage account
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
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
  name                 = var.index_document
  storage_account_name = azurerm_storage_account.sa.name
  # The name of the container must be "$web" to enable static website hosting
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/html"
  source_content         = var.source_content
}
