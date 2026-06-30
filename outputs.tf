output "resource_group_name" {
  description = "Name of the Resource Group"
  value       = module.resourcegroup.name
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.network.vnet_name
}

