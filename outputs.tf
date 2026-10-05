output "hostname" {
  description = "The hostname of the Web PubSub service."
  value       = azapi_resource.this.output.properties.hostName
}

output "name" {
  description = "The name of the Web PubSub service."
  value       = azapi_resource.this.name
}

output "provisioning_state" {
  description = "The provisioning state of the Web PubSub service returned by Azure."
  value       = azapi_resource.this.output.properties.provisioningState
}

output "public_port" {
  description = "The public port of the Web PubSub service."
  value       = azapi_resource.this.output.properties.publicPort
}

output "resource_id" {
  description = "The resource ID of the Web PubSub service."
  value       = azapi_resource.this.id
}

output "server_port" {
  description = "The server port of the Web PubSub service."
  value       = azapi_resource.this.output.properties.serverPort
}

output "system_assigned_mi_principal_id" {
  description = "The principal ID of the system-assigned managed identity, or null when it is disabled."
  value       = var.managed_identities.system_assigned ? azapi_resource.this.output.identity.principalId : null
}

output "system_assigned_mi_tenant_id" {
  description = "The tenant ID of the system-assigned managed identity, or null when it is disabled."
  value       = var.managed_identities.system_assigned ? azapi_resource.this.output.identity.tenantId : null
}
