output "profile_id" {
  description = "Azure Front Door profile resource ID."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "profile_name" {
  description = "Azure Front Door profile name."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "resource_guid" {
  description = "Front Door profile resource GUID used in the X-Azure-FDID header."
  value       = azurerm_cdn_frontdoor_profile.this.resource_guid
}

output "endpoint_id" {
  description = "Front Door endpoint resource ID."
  value       = azurerm_cdn_frontdoor_endpoint.this.id
}

output "endpoint_host_name" {
  description = "Front Door endpoint host name."
  value       = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "origin_group_ids" {
  description = "Origin group resource IDs keyed by logical name."
  value       = { for key, group in azurerm_cdn_frontdoor_origin_group.this : key => group.id }
}

output "origin_ids" {
  description = "Origin resource IDs keyed by logical name."
  value       = { for key, origin in azurerm_cdn_frontdoor_origin.this : key => origin.id }
}

output "route_ids" {
  description = "Route resource IDs keyed by logical name."
  value       = { for key, route in azurerm_cdn_frontdoor_route.this : key => route.id }
}

output "security_policy_id" {
  description = "Front Door security policy attachment ID, or null when WAF is not attached."
  value       = try(azurerm_cdn_frontdoor_security_policy.this[0].id, null)
}

output "diagnostic_setting_ids" {
  description = "Diagnostic setting IDs keyed by logical name."
  value       = { for key, setting in azurerm_monitor_diagnostic_setting.this : key => setting.id }
}
