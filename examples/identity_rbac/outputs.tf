output "resource_group_id" {
  description = "The resource group created by the example."
  value       = azapi_resource.resource_group.id
}

output "resource_id" {
  description = "The Web PubSub service resource ID."
  value       = module.test.resource_id
}

output "user_assigned_identity_resource_id" {
  description = "The user-assigned managed identity attached to Web PubSub and granted the service data-plane role."
  value       = azapi_resource.user_assigned_identity.id
}

output "user_assigned_identity_client_id" {
  description = "The client ID for configuring a workload to use the user-assigned managed identity."
  value       = azapi_resource.user_assigned_identity.output.properties.clientId
}

output "user_assigned_identity_principal_id" {
  description = "The principal ID used by the Web PubSub data-plane role assignment."
  value       = azapi_resource.user_assigned_identity.output.properties.principalId
}

output "role_assignment_resource_id" {
  description = "The Web PubSub Service Reader role assignment resource ID."
  value       = module.test.role_assignments["workload"]
}
