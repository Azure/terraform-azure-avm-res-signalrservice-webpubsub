output "resource_group_id" {
  description = "The resource group created by the example."
  value       = azapi_resource.resource_group.id
}

output "resource_id" {
  description = "The Socket.IO service resource ID."
  value       = module.test.resource_id
}

output "hostname" {
  description = "The Socket.IO service hostname."
  value       = module.test.hostname
}

output "service_mode" {
  description = "The configured Socket.IO service mode."
  value       = "Serverless"
}
