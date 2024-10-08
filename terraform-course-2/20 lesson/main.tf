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

# Create windows virtual machine
resource "azurerm_windows_virtual_machine" "app_vm" {
  name                = "appvm"
  resource_group_name = azurerm_resource_group.app-rg.name
  location            = azurerm_resource_group.app-rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "demouser"
  admin_password      = azurerm_key_vault_secret.vmpassword.value

  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_resource_group.app-rg,
    azurerm_network_interface.app_interface,
    azurerm_key_vault_secret.vmpassword
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

resource "azurerm_key_vault" "app_vault" {
  name                       = "terraformappvaulttt"
  location                   = azurerm_resource_group.app-rg.location
  resource_group_name        = azurerm_resource_group.app-rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set",
    ]
    storage_permissions = [
      "Get",
    ]
  }

  depends_on = [
    azurerm_resource_group.app-rg
  ]
}

# Configuring a secret inside key vault
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = "Azure@123"
  key_vault_id = azurerm_key_vault.app_vault.id
  depends_on   = [azurerm_key_vault.app_vault]

}
