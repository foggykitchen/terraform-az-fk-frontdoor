module "nginx" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-compute.git?ref=v0.4.1"

  name                = "${var.name_prefix}-nginx"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  deployment_mode     = "vm"
  subnet_id           = module.vnet.subnet_ids["fk-private-backend"]
  admin_username      = var.admin_username
  ssh_public_key      = tls_private_key.ssh.public_key_openssh
  vm_size             = var.vm_size
  custom_data         = base64encode(templatefile("${path.module}/cloud-init-nginx.yaml.tftpl", {}))
  app_gateway_attachment = {
    backend_pool_id = module.application_gateway.backend_address_pool_ids["nginx"]
  }

  tags = var.tags

  depends_on = [module.backend_nsg, module.nat_gateway]
}
