module "application_gateway_public_ip" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-public-ip.git?ref=v1.0.0"

  name                = "${var.name_prefix}-appgw-pip"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}
