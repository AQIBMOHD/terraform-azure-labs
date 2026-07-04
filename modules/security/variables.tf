variable "resource_group_name" {
  description = "Azure Resource Group Name"
  type        = string
}

variable "location"{
  description = "Azure Region"
  type        = string
}

 
 variable "frontend_subnet_id"{
    description = "frontend subnet id"
    type        = string
 }
 
 variable "backend_subnet_id"{
    description = "backend subnet id"
    type        = string
 } 

 variable "naming_prefix"{
    type = string
 }

 