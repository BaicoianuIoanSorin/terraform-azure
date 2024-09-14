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

# variables
variable "source_address_prefix" {
  description = "The source address prefix for the security rule"
  type        = string
}

# create a resource group in azure
# first argument - resource type (azurerm_resource_group), second argument - resource name (mtc-rg)
resource "azurerm_resource_group" "mtc-rg" {
  name     = "mtc-rg"
  location = "East US"
  tags = {
    environment = "dev"
  }
}

# create a virtual network in the resource group
resource "azurerm_virtual_network" "mtc-vn" {
  name                = "mtc-vn"
  resource_group_name = azurerm_resource_group.mtc-rg.name
  location            = azurerm_resource_group.mtc-rg.location
  # address space for subnet
  address_space = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

# create a subnet in the virtual network
# you have to create the virtual network before creating the subnet
resource "azurerm_subnet" "mtc-subnet" {
  name                 = "mtc-subnet"
  resource_group_name  = azurerm_resource_group.mtc-rg.name
  virtual_network_name = azurerm_virtual_network.mtc-vn.name
  address_prefixes     = ["10.123.1.0/24"]
}

# create a network security group
resource "azurerm_network_security_group" "mtc-sg" {
  name                = "mtc-sg"
  location            = azurerm_resource_group.mtc-rg.location
  resource_group_name = azurerm_resource_group.mtc-rg.name

  tags = {
    environment = "dev"
  }
}

# create a security rule in the network security group
resource "azurerm_network_security_rule" "mtc-dev-rule" {
  name                        = "mtc-dev-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.source_address_prefix
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.mtc-rg.name
  network_security_group_name = azurerm_network_security_group.mtc-sg.name
}

