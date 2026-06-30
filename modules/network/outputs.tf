


output "vnet_name" {
  description = "The name of the created virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "The ID of the created virtual network"
  value       = azurerm_virtual_network.vnet.id
}


output "frontend_subnet_id" {
  description = "The ID of the frontend subnet"
  value       = azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  description = "The ID of the backend subnet"
  value       = azurerm_subnet.backend.id
}

