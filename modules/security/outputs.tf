output "frontend_nsg_id" {
  description = "Frontend NSG ID"
  value       = azurerm_network_security_group.frontend_nsg.id
}

output "backend_nsg_id" {
  description = "Backend NSG ID"
  value       = azurerm_network_security_group.backend_nsg.id
}

