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
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.app_set.id

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
    azurerm_availability_set.app_set
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

# Create the data disk
resource "azurerm_managed_disk" "data_disk" {
  name                 = "data-disk"
  location             = azurerm_resource_group.app-rg.location
  resource_group_name  = azurerm_resource_group.app-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 16

  depends_on = [azurerm_resource_group.app-rg]
}

#Then we need to attach the data disk to the Azure Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  managed_disk_id    = azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.app_vm.id
  lun                = "0"
  caching            = "ReadWrite"
  depends_on = [
    azurerm_windows_virtual_machine.app_vm,
    azurerm_managed_disk.data_disk
  ]
}

resource "azurerm_availability_set" "app_set" {
  name                         = "appset"
  location                     = azurerm_resource_group.app-rg.location
  resource_group_name          = azurerm_resource_group.app-rg.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3

  depends_on = [azurerm_resource_group.app-rg]
}

resource "azurerm_storage_account" "appstoreaccount" {
  name                     = "terraformappstore3108"
  resource_group_name      = azurerm_resource_group.app-rg.name
  location                 = azurerm_resource_group.app-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true

  depends_on = [azurerm_resource_group.app-rg]
}

resource "azurerm_storage_container" "data-stor-container" {
  name                  = "data-stor-container"
  storage_account_name  = azurerm_storage_account.appstoreaccount.name
  container_access_type = "blob"
  depends_on            = [azurerm_storage_account.appstoreaccount]
}

# Here we are uploading our IIS Configuration script as a blob
# to the Azure Storage account
resource "azurerm_storage_blob" "IIS_Config" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = azurerm_storage_account.appstoreaccount.name
  storage_container_name = azurerm_storage_container.data-stor-container.name
  type                   = "Block"
  source                 = "scripts/IIS_Config.ps1"

  depends_on = [azurerm_storage_container.data-stor-container]

}

# For installing virtual machine extension, for example installing the CustomScriptExtension

resource "azurerm_virtual_machine_extension" "vm_extension_cs" {
  name                 = "appvm-extension-custom-script"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on           = [azurerm_storage_blob.IIS_Config, azurerm_windows_virtual_machine.app_vm]

  settings = jsonencode(
    {
      "fileUris" : ["https://${azurerm_storage_account.appstoreaccount.name}.blob.core.windows.net/${azurerm_storage_container.data-stor-container.name}/${azurerm_storage_blob.IIS_Config.name}"],
      "commandToExecute" : "powershell -ExecutionPolicy Unrestricted -file ${azurerm_storage_blob.IIS_Config.name}"
    }
  )
}

resource "azurerm_network_security_group" "app-nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.app-rg.location
  resource_group_name = azurerm_resource_group.app-rg.name

  # We are creating a rule to allow traffic on port 80
  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_resource_group.app-rg]
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.app-nsg.id

  depends_on = [azurerm_subnet.SubnetA, azurerm_network_security_group.app-nsg]
}




