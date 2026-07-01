variable "resource_group_name" {
  description = "Azure Resource Group Nmae"
  type        = string
}

variable "location" {
  description = "Azure Region"
  type        = string
}



variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
}

variable "address_space" {
  description = "Vnet Address Space"
  type        = list(string)
}
