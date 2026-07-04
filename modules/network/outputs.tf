


output "vnet_name" {
  description = "The name of the virtual network"
  value       = data.azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = data.azurerm_virtual_network.vnet.id
}


output "frontend_subnet_id" {
  description = "The ID of the frontend subnet"
  value       = data.azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  description = "The ID of the backend subnet"
  value       = data.azurerm_subnet.backend.id
}

