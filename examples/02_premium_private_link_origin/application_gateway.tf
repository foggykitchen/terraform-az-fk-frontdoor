locals {
  listener_hostname = "appgw-origin.internal"
}

module "application_gateway" {
  source = "git::https://github.com/foggykitchen/terraform-az-fk-application-gateway.git?ref=v0.2.0"

  name                = "${var.name_prefix}-appgw"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  location            = azurerm_resource_group.foggykitchen_rg.location
  gateway_subnet_id   = module.vnet.subnet_ids["fk-application-gateway"]
  sku_name            = "Standard_v2"
  public_ip_id        = module.application_gateway_public_ip.id

  private_frontend = {
    subnet_id                      = module.vnet.subnet_ids["fk-application-gateway"]
    private_ip_address_allocation  = "Static"
    private_ip_address             = var.application_gateway_private_ip
    private_link_configuration_key = "frontdoor"
  }

  private_link_configurations = {
    frontdoor = {
      name = "frontdoor"
      ip_configurations = {
        primary = {
          name      = "primary"
          subnet_id = module.vnet.subnet_ids["fk-application-gateway-private-link"]
          primary   = true
        }
      }
    }
  }

  frontend_ports = {
    http = { port = 80 }
  }

  backend_address_pools = {
    nginx = {}
  }

  probes = {
    nginx = {
      protocol = "Http"
      path     = "/health"
      host     = local.listener_hostname
    }
  }

  backend_http_settings = {
    nginx = {
      port      = 80
      protocol  = "Http"
      probe_key = "nginx"
      host_name = local.listener_hostname
    }
  }

  http_listeners = {
    private = {
      frontend_type     = "private"
      frontend_port_key = "http"
      protocol          = "Http"
      host_name         = local.listener_hostname
    }
  }

  request_routing_rules = {
    nginx = {
      priority                  = 100
      rule_type                 = "Basic"
      http_listener_key         = "private"
      backend_address_pool_key  = "nginx"
      backend_http_settings_key = "nginx"
    }
  }

  tags = var.tags
}
