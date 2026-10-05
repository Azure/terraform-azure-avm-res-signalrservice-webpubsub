output "resource_id" {
  description = "The Web PubSub service resource ID."
  value       = module.test.resource_id
}

output "hostname" {
  description = "The Web PubSub service hostname."
  value       = module.test.hostname
}

output "name" {
  description = "The generated Web PubSub service name."
  value       = module.test.name
}

output "resource_group_id" {
  description = "The resource group created by the example and passed to the module as parent_id."
  value       = azapi_resource.resource_group.id
}

output "provisioning_state" {
  description = "The Web PubSub service provisioning state returned by Azure."
  value       = module.test.provisioning_state
}

output "public_port" {
  description = "The Web PubSub client connection port."
  value       = module.test.public_port
}

output "server_port" {
  description = "The Web PubSub server connection port."
  value       = module.test.server_port
}
