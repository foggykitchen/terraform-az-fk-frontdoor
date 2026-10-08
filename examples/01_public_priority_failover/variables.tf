variable "resource_group_name" {
  description = "Resource Group created for the complete two-region example."
  type        = string
  default     = "fk-frontdoor-failover-rg"
}

variable "name_prefix" {
  description = "Prefix used for resources in both regions."
  type        = string
  default     = "fk-fd-failover"
}

variable "location" {
  description = "Azure region hosting the primary origin."
  type        = string
  default     = "westeurope"
}

variable "standby_location" {
  description = "Azure region hosting the standby origin."
  type        = string
  default     = "northeurope"
}

variable "primary_vnet_address_space" {
  type    = string
  default = "10.10.0.0/16"
}

variable "primary_backend_subnet_prefix" {
  type    = string
  default = "10.10.1.0/24"
}

variable "standby_vnet_address_space" {
  type    = string
  default = "10.20.0.0/16"
}

variable "standby_backend_subnet_prefix" {
  type    = string
  default = "10.20.1.0/24"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "tags" {
  type = map(string)
  default = {
    project = "foggykitchen"
    module  = "terraform-az-fk-frontdoor"
    example = "01_public_priority_failover"
    env     = "dev"
  }
}
