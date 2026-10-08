output "frontdoor_endpoint_host_name" {
  description = "Public Azure Front Door endpoint used to test routing and failover."
  value       = module.frontdoor.endpoint_host_name
}

output "frontdoor_profile_id" {
  value = module.frontdoor.profile_id
}

output "primary_origin_public_ip" {
  value = module.primary_load_balancer.public_ip_address
}

output "standby_origin_public_ip" {
  value = module.standby_load_balancer.public_ip_address
}

output "primary_vm_id" {
  value = module.primary_compute.vm_id
}

output "standby_vm_id" {
  value = module.standby_compute.vm_id
}
