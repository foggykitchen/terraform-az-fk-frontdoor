module "vnet" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-vnet.git?ref=v0.1.2"

  name                = "${var.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  address_space       = [var.vnet_address_space]

  subnets = {
    fk-application-gateway = {
      address_prefixes = [var.application_gateway_subnet_prefix]
    }
    fk-application-gateway-private-link = {
      address_prefixes                              = [var.private_link_subnet_prefix]
      private_link_service_network_policies_enabled = false
    }
    fk-private-backend = {
      address_prefixes = [var.backend_subnet_prefix]
    }
  }

  tags = var.tags
}
