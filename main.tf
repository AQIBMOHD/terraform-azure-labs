module "resourcegroup" {
  source = "./modules/resource-group"
  resource_group_name = var.resource_group_name
  location = var.location
}


resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = module.resourcegroup.location # <-- Referring to module output
  resource_group_name = module.resourcegroup.name     # <-- Referring to module output
  address_space       = var.address_space
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend-snet"
  resource_group_name  = module.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend-snet"
  resource_group_name  = module.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]


}

resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  resource_group_name  = module.resourcegroup.name
  location            = module.resourcegroup.location


}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
  resource_group_name  = module.resourcegroup.name
  location            = module.resourcegroup.location

}
resource "azurerm_network_security_rule" "frontend_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name  = module.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name


}

resource "azurerm_network_security_rule" "frontend_https" {
  name      = "allow-https"
  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "443"

  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name  = module.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

resource "azurerm_network_security_rule" "frontend_ssh" {
  name      = "allow-ssh"
  priority  = 120
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "22"

  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name  = module.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}


resource "azurerm_network_security_rule" "backend_api" {
  name      = "allow-api"
  priority  = 100
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "3000"

  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name  = module.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name

}

resource "azurerm_network_security_rule" "backend_ssh" {
  name      = "allow-ssh"
  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"


  source_port_range      = "*"
  destination_port_range = "22"

  source_address_prefix      = "*"
  destination_address_prefix = "*"


  resource_group_name  = module.resourcegroup.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name



}

resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}


resource "azurerm_public_ip" "frontend_pip" {
  name                = "frontend-pip"
  location            = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name

  allocation_method = "Static"
  sku               = "Standard"

}

resource "azurerm_network_interface" "frontend_nic" {
  name                = "frontend_nic"
  location            = module.resourcegroup.location
  resource_group_name = module.resourcegroup.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_pip.id
  }


}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = "frontend-vm"
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
  size                = "Standard_B2as_v2"

  admin_username = "aqib"
  admin_password = "aqibnaqvi@1234"

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.frontend_nic.id
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





