module "primary_vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "${var.name_prefix}-primary-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  address_space       = [var.primary_vnet_address_space]
  subnets = {
    fk-primary-backend = { address_prefixes = [var.primary_backend_subnet_prefix] }
  }
  tags = var.tags
}

module "standby_vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "${var.name_prefix}-standby-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.standby_location
  address_space       = [var.standby_vnet_address_space]
  subnets = {
    fk-standby-backend = { address_prefixes = [var.standby_backend_subnet_prefix] }
  }
  tags = var.tags
}
