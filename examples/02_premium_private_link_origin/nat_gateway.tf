module "nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = "${var.name_prefix}-natgw"
  public_ip_name      = "${var.name_prefix}-natgw-pip"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  create_public_ip    = true
  subnet_associations = {
    backend = { subnet_id = module.vnet.subnet_ids["fk-private-backend"] }
  }

  tags = var.tags
}
