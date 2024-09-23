terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.9.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_group = "app-rg"
  location       = "North Europe"
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "app-rg" {
  name     = local.resource_group
  location = local.location

  tags = {
    environment = "course-2"
  }
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "course-2"
  }

  depends_on = [azurerm_resource_group.app-rg]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.app-rg.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [
    azurerm_resource_group.app-rg,
    azurerm_virtual_network.app_network,
  ]
}

# Create network interface
resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_resource_group.app-rg,
    azurerm_public_ip.app_public_ip,
    azurerm_subnet.SubnetA
  ]
}

# Create linux virtual machine
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linuxvm"
  resource_group_name = azurerm_resource_group.app-rg.name
  location            = azurerm_resource_group.app-rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "linuxuser"
  # when using the admin_password, you should also specify disable_password_authentication = false, by default is true
  admin_password                  = "Azure@123"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_resource_group.app-rg,
    azurerm_network_interface.app_interface,
  ]
}

# Create the public ip address
resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = azurerm_resource_group.app-rg.name
  location            = azurerm_resource_group.app-rg.location
  allocation_method   = "Static"

  depends_on = [azurerm_resource_group.app-rg]
}
