module "primary_compute" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "${var.name_prefix}-primary-vm"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  deployment_mode     = "vm"
  subnet_id           = module.primary_vnet.subnet_ids["fk-primary-backend"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh.public_key_openssh
  vm_size             = var.vm_size
  lb_attachment       = { backend_pool_id = module.primary_load_balancer.backend_pool_id }
  custom_data = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {
    region_name = var.location
    role_name   = "primary"
  }))
  tags = var.tags

  depends_on = [module.primary_nat_gateway, module.primary_nsg]
}

module "standby_compute" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "${var.name_prefix}-standby-vm"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.standby_location
  deployment_mode     = "vm"
  subnet_id           = module.standby_vnet.subnet_ids["fk-standby-backend"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh.public_key_openssh
  vm_size             = var.vm_size
  lb_attachment       = { backend_pool_id = module.standby_load_balancer.backend_pool_id }
  custom_data = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {
    region_name = var.standby_location
    role_name   = "standby"
  }))
  tags = var.tags

  depends_on = [module.standby_nat_gateway, module.standby_nsg]
}
