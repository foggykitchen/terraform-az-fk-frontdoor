module "backend_nsg" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-nsg.git?ref=v1.0.1"

  name                = "${var.name_prefix}-backend-nsg"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  subnet_associations = {
    backend = { subnet_id = module.vnet.subnet_ids["fk-private-backend"] }
  }

  rules = [{
    name                       = "AllowApplicationGatewayHttp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.application_gateway_subnet_prefix
    destination_address_prefix = var.backend_subnet_prefix
  }]

  tags = var.tags
}
