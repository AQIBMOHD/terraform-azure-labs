output "vm_name" {
  description = "The name of the Virtual Machine"
  value       = azurerm_linux_virtual_machine.frontend_vm.name
}

output "public_ip_address" {
  description = "The public IP address of the Virtual Machine"
  value       = azurerm_public_ip.frontend_pip.ip_address
}


