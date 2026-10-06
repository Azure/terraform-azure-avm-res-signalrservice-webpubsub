output "diagnostic_settings" {
  description = "Diagnostic setting resource IDs, keyed by the diagnostic_settings input keys."
  value       = { for key, setting in azapi_resource.diagnostic_settings : key => setting.id }
}

output "lock_resource_id" {
  description = "The resource ID of the Web PubSub management lock, or null when no lock is configured."
  value       = try(azapi_resource.lock[0].id, null)
}

output "private_endpoints" {
  description = "Private endpoint IDs, names, network interface IDs, DNS zone group IDs, lock IDs, and nested role assignment IDs, keyed by the private_endpoints input keys."
  value = {
    for key, endpoint in azapi_resource.private_endpoints : key => {
      resource_id                        = endpoint.id
      name                               = endpoint.name
      network_interface_resource_ids     = [for nic in endpoint.output.properties.networkInterfaces : nic.id]
      private_dns_zone_group_resource_id = try(azapi_resource.private_dns_zone_groups[key].id, null)
      lock_resource_id                   = try(azapi_resource.private_endpoint_locks[key].id, null)
      role_assignment_resource_ids = {
        for assignment_key, assignment in module.avm_interfaces.role_assignments_private_endpoint_azapi :
        assignment.assignment_key => azapi_resource.private_endpoint_role_assignments[assignment_key].id
        if assignment.pe_key == key
      }
    }
  }
}

output "role_assignments" {
  description = "Web PubSub role assignment resource IDs, keyed by the role_assignments input keys."
  value       = { for key, assignment in azapi_resource.role_assignments : key => assignment.id }
}
