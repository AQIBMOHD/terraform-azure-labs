data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  
}
data  "azurerm_subnet" "frontend" {
  name                 = "${var.naming_prefix}-frontend-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
   
}

data "azurerm_subnet" "backend" {
  name                 = "${var.naming_prefix}-backend-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name

  

}