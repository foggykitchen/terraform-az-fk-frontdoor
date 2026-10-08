module "frontdoor" {
  source = "../.."

  name                = "${var.name_prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  sku_name            = "Standard_AzureFrontDoor"
  endpoint = {
    name = "${var.name_prefix}-endpoint"
  }

  origin_groups = {
    web = {
      health_probe = {
        path         = "/health"
        protocol     = "Http"
        request_type = "HEAD"
      }
      load_balancing = {
        sample_size                 = 4
        successful_samples_required = 3
      }
    }
  }

  origins = {
    primary = {
      origin_group_key               = "web"
      host_name                      = module.primary_load_balancer.public_ip_address
      certificate_name_check_enabled = false
      http_port                      = 80
      priority                       = 1
      weight                         = 1000
    }
    standby = {
      origin_group_key               = "web"
      host_name                      = module.standby_load_balancer.public_ip_address
      certificate_name_check_enabled = false
      http_port                      = 80
      priority                       = 2
      weight                         = 1000
    }
  }

  routes = {
    default = {
      origin_group_key    = "web"
      patterns_to_match   = ["/*"]
      forwarding_protocol = "HttpOnly"
    }
  }

  tags = var.tags
}
