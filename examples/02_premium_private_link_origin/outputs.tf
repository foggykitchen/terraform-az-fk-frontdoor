output "frontdoor_endpoint_host_name" {
  description = "Front Door endpoint hostname used for runtime testing."
  value       = module.frontdoor.endpoint_host_name
}

output "frontdoor_profile_id" {
  description = "Front Door Premium profile resource ID."
  value       = module.frontdoor.profile_id
}

output "application_gateway_id" {
  description = "Private Application Gateway resource ID."
  value       = module.application_gateway.application_gateway_id
}

output "application_gateway_private_frontend_ip" {
  description = "Private frontend IP used by the Application Gateway listener."
  value       = var.application_gateway_private_ip
}

output "application_gateway_private_link_service_id" {
  description = "Derived Azure-managed Private Link Service ID consumed by the Front Door origin."
  value       = module.application_gateway.private_link_service_ids["frontdoor"]
}

output "application_gateway_private_link_configuration_name" {
  description = "Application Gateway Private Link configuration name."
  value       = module.application_gateway.private_link_configuration_names["frontdoor"]
}

output "backend_vm_id" {
  description = "Private NGINX backend VM resource ID."
  value       = module.nginx.vm_id
}
