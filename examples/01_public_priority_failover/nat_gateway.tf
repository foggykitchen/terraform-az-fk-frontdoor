module "primary_nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = "${var.name_prefix}-primary-natgw"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  public_ip_name      = "${var.name_prefix}-primary-natgw-pip"
  subnet_associations = {
    backend = { subnet_id = module.primary_vnet.subnet_ids["fk-primary-backend"] }
  }
  tags = var.tags
}

module "standby_nat_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-natgw.git?ref=v1.1.1"

  name                = "${var.name_prefix}-standby-natgw"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.standby_location
  public_ip_name      = "${var.name_prefix}-standby-natgw-pip"
  subnet_associations = {
    backend = { subnet_id = module.standby_vnet.subnet_ids["fk-standby-backend"] }
  }
  tags = var.tags
}
