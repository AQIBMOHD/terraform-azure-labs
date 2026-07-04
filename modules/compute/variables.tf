variable "resource_group_name"{
    type = string
}

variable "location" {
    type = string
}

variable "frontend_subnet_id"{
    description="The ID of the frontend subnet to attach the NIC"
    type = string
}

variable "naming_prefix"{
    type = string
 }


