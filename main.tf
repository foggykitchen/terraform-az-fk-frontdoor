locals {
  origins_by_group = {
    for group_key in keys(var.origin_groups) : group_key => [
      for origin_key, origin in var.origins : origin_key if origin.origin_group_key == group_key
    ]
  }
  private_link_origins = [for origin in values(var.origins) : origin if origin.private_link != null]
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  sku_name                 = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds
  tags                     = var.tags

  lifecycle {
    precondition {
      condition     = length(local.private_link_origins) == 0 || var.sku_name == "Premium_AzureFrontDoor"
      error_message = "Private Link origins require sku_name = Premium_AzureFrontDoor."
    }

    precondition {
      condition     = alltrue([for group_key, origin_keys in local.origins_by_group : length(origin_keys) > 0])
      error_message = "Every origin group must contain at least one configured origin."
    }
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = var.endpoint.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = var.endpoint.enabled
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = var.origin_groups

  name                                                      = coalesce(each.value.name, each.key)
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled                                  = each.value.session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = each.value.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  health_probe {
    interval_in_seconds = each.value.health_probe.interval_in_seconds
    path                = each.value.health_probe.path
    protocol            = each.value.health_probe.protocol
    request_type        = each.value.health_probe.request_type
  }

  load_balancing {
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

  name                           = coalesce(each.value.name, each.key)
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  enabled                        = each.value.enabled
  host_name                      = each.value.host_name
  origin_host_header             = each.value.origin_host_header
  certificate_name_check_enabled = each.value.certificate_name_check_enabled
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  priority                       = each.value.priority
  weight                         = each.value.weight

  dynamic "private_link" {
    for_each = each.value.private_link == null ? [] : [each.value.private_link]
    content {
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.routes

  name                            = coalesce(each.value.name, each.key)
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  cdn_frontdoor_origin_ids        = [for origin_key in local.origins_by_group[each.value.origin_group_key] : azurerm_cdn_frontdoor_origin.this[origin_key].id]
  patterns_to_match               = each.value.patterns_to_match
  supported_protocols             = each.value.supported_protocols
  forwarding_protocol             = each.value.forwarding_protocol
  https_redirect_enabled          = each.value.https_redirect_enabled
  link_to_default_domain          = each.value.link_to_default_domain
  enabled                         = each.value.enabled
  cdn_frontdoor_origin_path       = each.value.cdn_frontdoor_origin_path
  cdn_frontdoor_rule_set_ids      = each.value.cdn_frontdoor_rule_set_ids
  cdn_frontdoor_custom_domain_ids = each.value.cdn_frontdoor_custom_domain_ids

  dynamic "cache" {
    for_each = each.value.cache == null ? [] : [each.value.cache]
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = var.frontdoor_firewall_policy_id == null ? 0 : 1

  name                     = var.security_policy_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.frontdoor_firewall_policy_id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = coalesce(each.value.name, each.key)
  target_resource_id             = azurerm_cdn_frontdoor_profile.this.id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = each.value.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  # `metric` remains available in AzureRM 4.81.0 and preserves the declared
  # AzureRM 3.100.0 compatibility floor. `enabled_metric` is newer.
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
