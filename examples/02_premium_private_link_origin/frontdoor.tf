module "frontdoor" {
  source = "../.."

  name                = "${var.name_prefix}-frontdoor"
  resource_group_name = azurerm_resource_group.foggykitchen_rg.name
  sku_name            = "Premium_AzureFrontDoor"
  endpoint = {
    name = "${var.name_prefix}-endpoint"
  }

  origin_groups = {
    private_app = {
      name = "private-app"
      health_probe = {
        path         = "/health"
        protocol     = "Http"
        request_type = "HEAD"
      }
    }
  }

  origins = {
    application_gateway = {
      name                           = "application-gateway"
      origin_group_key               = "private_app"
      host_name                      = local.listener_hostname
      origin_host_header             = local.listener_hostname
      certificate_name_check_enabled = true
      http_port                      = 80
      priority                       = 1
      weight                         = 1000
      private_link = {
        location               = var.location
        private_link_target_id = module.application_gateway.private_link_service_ids["frontdoor"]
        request_message        = "Approve Azure Front Door access to the private Application Gateway origin"
      }
    }
  }

  routes = {
    default = {
      origin_group_key    = "private_app"
      patterns_to_match   = ["/*"]
      forwarding_protocol = "HttpOnly"
    }
  }

  diagnostic_settings = var.log_analytics_workspace_id == null ? {} : {
    frontdoor = {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags

  depends_on = [module.application_gateway]
}
