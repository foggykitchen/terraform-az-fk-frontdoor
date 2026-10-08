variable "resource_group_name" {
  description = "Resource Group created for the Premium Private Link example."
  type        = string
  default     = "fk-frontdoor-private-link-rg"
}

variable "location" {
  description = "Azure region for the private Application Gateway origin."
  type        = string
  default     = "westeurope"
}

variable "name_prefix" {
  description = "Prefix used for resources in the example."
  type        = string
  default     = "fk-fd-private"
}

variable "vnet_address_space" {
  type    = string
  default = "10.40.0.0/16"
}

variable "application_gateway_subnet_prefix" {
  type    = string
  default = "10.40.1.0/24"
}

variable "private_link_subnet_prefix" {
  type    = string
  default = "10.40.0.0/24"
}

variable "backend_subnet_prefix" {
  type    = string
  default = "10.40.2.0/24"
}

variable "application_gateway_private_ip" {
  type    = string
  default = "10.40.1.10"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "log_analytics_workspace_id" {
  description = "Optional existing Log Analytics Workspace resource ID for Front Door diagnostics."
  type        = string
  default     = null
}

variable "tags" {
  type = map(string)
  default = {
    project = "foggykitchen"
    module  = "terraform-az-fk-frontdoor"
    example = "02_premium_private_link_origin"
    env     = "dev"
  }
}
