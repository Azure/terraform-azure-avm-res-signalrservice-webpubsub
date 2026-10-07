output "resource_id" {
  description = "The Web PubSub service resource ID."
  value       = module.test.resource_id
}

output "hostname" {
  description = "The normal Web PubSub hostname to use for connections; private DNS resolves it to the endpoint's private IP from the linked VNet."
  value       = module.test.hostname
}

output "resource_group_id" {
  description = "The resource group created by the example."
  value       = azapi_resource.resource_group.id
}

output "virtual_network_resource_id" {
  description = "The virtual network linked to the private DNS zone."
  value       = azapi_resource.virtual_network.id
}

output "subnet_resource_id" {
  description = "The dedicated private endpoint subnet."
  value       = "${azapi_resource.virtual_network.id}/subnets/private-endpoints"
}

output "private_dns_zone_resource_id" {
  description = "The privatelink.webpubsub.azure.com private DNS zone."
  value       = azapi_resource.private_dns_zone.id
}

output "private_dns_virtual_network_link_resource_id" {
  description = "The DNS virtual network link with auto-registration disabled."
  value       = azapi_resource.private_dns_virtual_network_link.id
}

output "private_endpoint_resource_id" {
  description = "The private endpoint created by the Web PubSub module."
  value       = module.test.private_endpoints["primary"].resource_id
}

output "private_endpoint_network_interface_resource_ids" {
  description = "The private endpoint's network interface IDs."
  value       = module.test.private_endpoints["primary"].network_interface_resource_ids
}

output "private_dns_zone_group_resource_id" {
  description = "The module-managed private DNS zone group that registers the private endpoint's DNS records."
  value       = module.test.private_endpoints["primary"].private_dns_zone_group_resource_id
}
