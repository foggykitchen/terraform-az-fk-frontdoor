locals {
  backend_nsg_rules = [
    {
      name                       = "AllowFrontDoorHttp"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "AzureFrontDoor.Backend"
      destination_address_prefix = "*"
      description                = "Allow Front Door backend traffic to NGINX through the regional Load Balancer."
    },
    {
      name                       = "AllowAzureLoadBalancerProbe"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
      description                = "Allow Azure Load Balancer health probes."
    }
  ]
}

module "primary_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "${var.name_prefix}-primary-nsg"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  rules               = local.backend_nsg_rules
  subnet_associations = {
    backend = { subnet_id = module.primary_vnet.subnet_ids["fk-primary-backend"] }
  }
  tags = var.tags
}

module "standby_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "${var.name_prefix}-standby-nsg"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.standby_location
  rules               = local.backend_nsg_rules
  subnet_associations = {
    backend = { subnet_id = module.standby_vnet.subnet_ids["fk-standby-backend"] }
  }
  tags = var.tags
}
