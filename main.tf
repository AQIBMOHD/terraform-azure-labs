module "resourcegroup" {
  source = "./modules/resource-group"
  resource_group_name = var.resource_group_name
  location = var.location
}


module "network"{
  source = "./modules/network"
  vnet_name = var.vnet_name
  address_space = var.address_space
  location = var.location
  resource_group_name = var.resource_group_name 

}



module "security"{
  source              = "./modules/security"
  frontend_subnet_id  = module.network.frontend_subnet_id 
  backend_subnet_id   = module.network.backend_subnet_id  
  resource_group_name = module.resourcegroup.name
  location            = module.resourcegroup.location
}






moved {
  from = azurerm_virtual_network.vnet
  to   = module.network.azurerm_virtual_network.vnet
}

moved {
  from = azurerm_subnet.frontend
  to   = module.network.azurerm_subnet.frontend
}

moved {
  from = azurerm_subnet.backend
  to   = module.network.azurerm_subnet.backend
}


# Security Module Migration (NSG Migration)
moved {
  from = azurerm_network_security_group.frontend_nsg
  to   = module.security.azurerm_network_security_group.frontend_nsg
}

moved {
  from = azurerm_network_security_group.backend_nsg
  to   = module.security.azurerm_network_security_group.backend_nsg
}

moved {
  from = azurerm_network_security_rule.frontend_http
  to   = module.security.azurerm_network_security_rule.frontend_http
}

moved {
  from = azurerm_network_security_rule.frontend_https
  to   = module.security.azurerm_network_security_rule.frontend_https
}

moved {
  from = azurerm_network_security_rule.frontend_ssh
  to   = module.security.azurerm_network_security_rule.frontend_ssh
}

moved {
  from = azurerm_network_security_rule.backend_api
  to   = module.security.azurerm_network_security_rule.backend_api
}

moved {
  from = azurerm_network_security_rule.backend_ssh
  to   = module.security.azurerm_network_security_rule.backend_ssh
}

moved {
  from = azurerm_subnet_network_security_group_association.frontend_assoc
  to   = module.security.azurerm_subnet_network_security_group_association.frontend_assoc
}

moved {
  from = azurerm_subnet_network_security_group_association.backend_assoc
  to   = module.security.azurerm_subnet_network_security_group_association.backend_assoc
}







