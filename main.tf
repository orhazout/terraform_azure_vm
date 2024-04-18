resource "azurerm_resource_group" "vm_rg" {
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_virtual_network" "main" {
  name                = "basic_vm_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.rg_location
  resource_group_name = var.rg_name

  depends_on =[azurerm_resource_group.vm_rg]
}

resource "azurerm_subnet" "vnet_subnet" {
  name                 = "vnet_subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  depends_on =[azurerm_resource_group.vm_rg, azurerm_virtual_network.main]
}

resource "azurerm_network_interface" "main" {
  name                = "vm_nic"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.vnet_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_subnet.vnet_subnet] 
}

resource "azurerm_virtual_machine" "basic_vm" {
  name                  = var.vm_name
  location              = var.rg_location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B2ts_v2"


  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "player1"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [azurerm_subnet.vnet_subnet, azurerm_network_interface.main] 
}