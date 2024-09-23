variable "location" {
  type        = string
  description = "The azure region in which the resources will be deployed"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The name of the resource group"
}

variable "storage_account_name" {
  description = "The name of the storage account"
}

variable "source_content" {
  description = "The content of the index.html file"
}

variable "index_document" {
  description = "The name of the index document"
}
