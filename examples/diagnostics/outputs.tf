output "resource_group_id" {
  description = "The resource group created by the example."
  value       = azapi_resource.resource_group.id
}

output "resource_id" {
  description = "The Web PubSub service resource ID."
  value       = module.test.resource_id
}

output "log_analytics_workspace_id" {
  description = "The Log Analytics workspace receiving Web PubSub resource logs."
  value       = azapi_resource.log_analytics_workspace.id
}

output "diagnostic_setting_resource_id" {
  description = "The resource ID of the module-managed diagnostic setting."
  value       = module.test.diagnostic_settings["logs"]
}
