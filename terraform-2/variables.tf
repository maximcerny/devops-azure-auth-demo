variable "environment" {
    description = "Environment name (dev, tst)"
    type        = string
}

variable "resource_group_name" {
    description = "Name of the existing resource group"
    type        = string
}

variable "location" {
    description = "Azure region"
    type        = string
    default     = "westeurope"
}

variable "vnet_address_space" {
    description = "Address space for virtual network"
    type        = list(string)
    default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
    description = "Address prefixes for subnet"
    type        = list(string)
    default     = ["10.0.1.0/24"]
}

variable "vm_size" {
    description = "Size of the virtual machine"
    type        = string
    default     = "Standard_B1s"
}

variable "admin_username" {
    description = "Admin username for VM"
    type        = string
    default     = "adminuser"
}

variable "admin_password" {
    description = "Admin password for VM"
    type        = string
    sensitive   = true
}
