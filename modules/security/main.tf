data "http" "my_public_ip" {
    url = "https://api.ipify.org"
}


resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "${var.naming_prefix}-frontend-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location


} 

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "${var.naming_prefix}-backend-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
 
}
resource "azurerm_network_security_rule" "frontend_http" {
  name                        = "${var.naming_prefix}-allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name


}

resource "azurerm_network_security_rule" "frontend_https" {
  name      = "${var.naming_prefix}-allow-https"
  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "443"

  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name  = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

resource "azurerm_network_security_rule" "frontend_ssh" {
  name      = "${var.naming_prefix}-allow-ssh"
  priority  = 120
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "22"

  source_address_prefix      = "${data.http.my_public_ip.response_body}/32"
  destination_address_prefix = "*"

  resource_group_name  = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}


resource "azurerm_network_security_rule" "backend_api" {
  name      = "${var.naming_prefix}-allow-api"
  priority  = 100
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range      = "*"
  destination_port_range = "3000"

  source_address_prefix      = "*"
  destination_address_prefix = "*"

  resource_group_name  = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name

}

resource "azurerm_network_security_rule" "backend_ssh" {
  name      = "${var.naming_prefix}-allow-ssh"
  priority  = 110
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"


  source_port_range      = "*"
  destination_port_range = "22"

  source_address_prefix      = "${data.http.my_public_ip.response_body}/32"
  destination_address_prefix = "*"


  resource_group_name  = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name



}
 
resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = var.frontend_subnet_id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = var.backend_subnet_id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}
