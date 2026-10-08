variable "name" {
  description = "Azure Front Door profile name."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "resource_group_name" {
  description = "Existing Resource Group containing the Front Door profile."
  type        = string
}

variable "sku_name" {
  description = "Front Door SKU: Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  type        = string
  default     = "Standard_AzureFrontDoor"

  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "response_timeout_seconds" {
  description = "Maximum origin response timeout in seconds."
  type        = number
  default     = 120

  validation {
    condition     = var.response_timeout_seconds >= 16 && var.response_timeout_seconds <= 240
    error_message = "response_timeout_seconds must be between 16 and 240."
  }
}

variable "endpoint" {
  description = "The single Front Door endpoint."
  type = object({
    name    = string
    enabled = optional(bool, true)
  })
}

variable "origin_groups" {
  description = "Origin groups keyed by logical name, including health probe and load-balancing settings."
  type = map(object({
    name                                                      = optional(string)
    session_affinity_enabled                                  = optional(bool, false)
    restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
    health_probe = object({
      interval_in_seconds = optional(number, 30)
      path                = optional(string, "/")
      protocol            = optional(string, "Https")
      request_type        = optional(string, "HEAD")
    })
    load_balancing = optional(object({
      additional_latency_in_milliseconds = optional(number, 50)
      sample_size                        = optional(number, 4)
      successful_samples_required        = optional(number, 3)
    }), {})
  }))

  validation {
    condition = length(var.origin_groups) > 0 && alltrue([
      for group in values(var.origin_groups) :
      contains(["Http", "Https"], group.health_probe.protocol) &&
      contains(["GET", "HEAD"], group.health_probe.request_type) &&
      group.health_probe.interval_in_seconds >= 1 && group.health_probe.interval_in_seconds <= 255 &&
      group.load_balancing.additional_latency_in_milliseconds >= 0 && group.load_balancing.additional_latency_in_milliseconds <= 1000 &&
      group.load_balancing.sample_size >= 0 && group.load_balancing.sample_size <= 255 &&
      group.load_balancing.successful_samples_required >= 0 && group.load_balancing.successful_samples_required <= group.load_balancing.sample_size
    ])
    error_message = "At least one valid origin group is required; verify probe protocol/request type and load-balancing sample ranges."
  }
}

variable "origins" {
  description = "Existing public or Private Link origins keyed by logical name. The module references origins and never creates regional origin resources."
  type = map(object({
    name                           = optional(string)
    origin_group_key               = string
    host_name                      = string
    origin_host_header             = optional(string)
    enabled                        = optional(bool, true)
    certificate_name_check_enabled = optional(bool, true)
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    priority                       = optional(number, 1)
    weight                         = optional(number, 500)
    private_link = optional(object({
      location               = string
      private_link_target_id = string
      request_message        = optional(string, "Request access for Azure Front Door Private Link origin")
      target_type            = optional(string)
    }))
  }))

  validation {
    condition = length(var.origins) > 0 && alltrue([
      for origin in values(var.origins) :
      contains(keys(var.origin_groups), origin.origin_group_key) &&
      origin.priority >= 1 && origin.priority <= 5 &&
      origin.weight >= 1 && origin.weight <= 1000 &&
      origin.http_port >= 1 && origin.http_port <= 65535 &&
      origin.https_port >= 1 && origin.https_port <= 65535
    ])
    error_message = "Each origin must reference an origin group and use priority 1..5, weight 1..1000, and valid ports."
  }

  validation {
    condition     = alltrue([for origin in values(var.origins) : origin.private_link == null || origin.certificate_name_check_enabled])
    error_message = "Private Link origins require certificate_name_check_enabled = true."
  }
}

variable "routes" {
  description = "Endpoint routes keyed by logical name. Each route maps paths to one origin group."
  type = map(object({
    name                            = optional(string)
    origin_group_key                = string
    patterns_to_match               = list(string)
    supported_protocols             = optional(set(string), ["Http", "Https"])
    forwarding_protocol             = optional(string, "HttpsOnly")
    https_redirect_enabled          = optional(bool, true)
    link_to_default_domain          = optional(bool, true)
    enabled                         = optional(bool, true)
    cdn_frontdoor_origin_path       = optional(string)
    cdn_frontdoor_rule_set_ids      = optional(set(string), [])
    cdn_frontdoor_custom_domain_ids = optional(set(string), [])
    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string))
      compression_enabled           = optional(bool, false)
      content_types_to_compress     = optional(list(string))
    }))
  }))

  validation {
    condition = length(var.routes) > 0 && alltrue([
      for route in values(var.routes) :
      contains(keys(var.origin_groups), route.origin_group_key) &&
      length(route.patterns_to_match) > 0 &&
      length(route.supported_protocols) > 0 &&
      alltrue([for protocol in route.supported_protocols : contains(["Http", "Https"], protocol)]) &&
      contains(["HttpOnly", "HttpsOnly", "MatchRequest"], route.forwarding_protocol)
    ])
    error_message = "Each route must reference an origin group, include patterns/protocols, and use a supported forwarding protocol."
  }
}

variable "frontdoor_firewall_policy_id" {
  description = "Optional existing azurerm_cdn_frontdoor_firewall_policy ID. The module never creates the policy."
  type        = string
  default     = null
}

variable "security_policy_name" {
  description = "Security policy attachment name used when frontdoor_firewall_policy_id is set."
  type        = string
  default     = "default-security-policy"
}

variable "diagnostic_settings" {
  description = "Azure Monitor diagnostic settings keyed by logical name. Log Analytics workspaces are externally managed."
  type = map(object({
    name                           = optional(string)
    log_analytics_workspace_id     = string
    log_analytics_destination_type = optional(string, "Dedicated")
    log_category_groups            = optional(set(string), ["allLogs"])
    metric_categories              = optional(set(string), ["AllMetrics"])
  }))
  default = {}
}

variable "tags" {
  description = "Tags assigned to the Front Door profile and endpoint."
  type        = map(string)
  default     = {}
}
