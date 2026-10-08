module "primary_load_balancer" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-loadbalancer.git?ref=v1.2.1"

  name                = "${var.name_prefix}-primary-lb"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.location
  public_lb           = true
  create_public_ip    = true
  public_ip_name      = "${var.name_prefix}-primary-lb-pip"
  frontend_name       = "public"
  backend_pool_name   = "nginx"
  probe = {
    name                = "http-health"
    protocol            = "Http"
    port                = 80
    request_path        = "/health"
    interval_in_seconds = 5
    number_of_probes    = 2
  }
  rule = {
    name          = "http"
    protocol      = "Tcp"
    frontend_port = 80
    backend_port  = 80
  }
  tags = var.tags
}

module "standby_load_balancer" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-loadbalancer.git?ref=v1.2.1"

  name                = "${var.name_prefix}-standby-lb"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = var.standby_location
  public_lb           = true
  create_public_ip    = true
  public_ip_name      = "${var.name_prefix}-standby-lb-pip"
  frontend_name       = "public"
  backend_pool_name   = "nginx"
  probe = {
    name                = "http-health"
    protocol            = "Http"
    port                = 80
    request_path        = "/health"
    interval_in_seconds = 5
    number_of_probes    = 2
  }
  rule = {
    name          = "http"
    protocol      = "Tcp"
    frontend_port = 80
    backend_port  = 80
  }
  tags = var.tags
}
