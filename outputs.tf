output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = module.resourcegroup.name
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "frontend_vm_name" {
  description = "Frontend Virtual Machine Name"
  value       = azurerm_linux_virtual_machine.frontend_vm.name
}