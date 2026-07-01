# 1 public Ip for VM 
resource "azurerm_public_ip" "frontend_pip"{
name ="frontend-pip" 
location = var.location
resource_group_name=var.resource_group_name
allocation_method="Static"
sku ="Standard"

}

#2 Network Interface (NIC) for VM
resource "azurerm_network_interface" "frontend_vm_nic"{
    name="frontend_vm_nic"
    location=var.location
    resource_group_name=var.resource_group_name

    ip_configuration{
        name= "internal"
        subnet_id =var.frontend_subnet_id
        private_ip_address_allocation = "Dynamic"
       public_ip_address_id = azurerm_public_ip.frontend_pip.id
    
  }
}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = "frontend-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2as_v2"
  admin_username      = "aqib"
  admin_password = "aqibnaqvi@23"

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.frontend_vm_nic.id
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

}
