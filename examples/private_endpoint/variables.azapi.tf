variable "resource_types" {
  type = object({
    resources_resource_groups                       = optional(string, "Microsoft.Resources/resourceGroups@2024-11-01")
    network_virtual_networks                        = optional(string, "Microsoft.Network/virtualNetworks@2024-05-01")
    network_private_dns_zones                       = optional(string, "Microsoft.Network/privateDnsZones@2024-06-01")
    network_private_dns_zones_virtual_network_links = optional(string, "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01")
    signalrservice_web_pub_sub = optional(object({
      signalrservice_web_pub_sub                        = optional(string)
      authorization_locks                               = optional(string)
      authorization_role_assignments                    = optional(string)
      insights_diagnostic_settings                      = optional(string)
      network_private_endpoints                         = optional(string)
      network_private_endpoints_private_dns_zone_groups = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions. Omitted module overrides use the module's tested defaults.

- `resources_resource_groups` - Resource group.
- `network_virtual_networks` - Virtual network and its inline subnet.
- `network_private_dns_zones` - Private DNS zone.
- `network_private_dns_zones_virtual_network_links` - Private DNS virtual network link.
- `signalrservice_web_pub_sub` - Overrides passed to the Web PubSub module.
- `signalrservice_web_pub_sub.signalrservice_web_pub_sub` - Web PubSub service.
- `signalrservice_web_pub_sub.authorization_locks` - Management locks.
- `signalrservice_web_pub_sub.authorization_role_assignments` - Role assignments.
- `signalrservice_web_pub_sub.insights_diagnostic_settings` - Diagnostic settings.
- `signalrservice_web_pub_sub.network_private_endpoints` - Private endpoints.
- `signalrservice_web_pub_sub.network_private_endpoints_private_dns_zone_groups` - Private DNS zone groups.
DESCRIPTION
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    resources_resource_groups                       = optional(list(string), [])
    network_virtual_networks                        = optional(list(string), [])
    network_private_dns_zones                       = optional(list(string), [])
    network_private_dns_zones_virtual_network_links = optional(list(string), [])
    signalrservice_web_pub_sub = optional(object({
      signalrservice_web_pub_sub                        = optional(list(string), [])
      authorization_locks                               = optional(list(string), [])
      authorization_role_assignments                    = optional(list(string), [])
      insights_diagnostic_settings                      = optional(list(string), [])
      network_private_endpoints                         = optional(list(string), [])
      network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths to ignore. Non-empty lists require Terraform 1.11 or later. Changes take effect only after apply; ignored configuration is not sent to Azure.

- `resources_resource_groups` - Resource group.
- `network_virtual_networks` - Virtual network and its inline subnet.
- `network_private_dns_zones` - Private DNS zone.
- `network_private_dns_zones_virtual_network_links` - Private DNS virtual network link.
- `signalrservice_web_pub_sub` - Ignored-path controls passed to the Web PubSub module.
- `signalrservice_web_pub_sub.signalrservice_web_pub_sub` - Web PubSub service.
- `signalrservice_web_pub_sub.authorization_locks` - Management locks.
- `signalrservice_web_pub_sub.authorization_role_assignments` - Role assignments.
- `signalrservice_web_pub_sub.insights_diagnostic_settings` - Diagnostic settings.
- `signalrservice_web_pub_sub.network_private_endpoints` - Private endpoints.
- `signalrservice_web_pub_sub.network_private_endpoints_private_dns_zone_groups` - Private DNS zone groups.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Optional retry configuration for all AzAPI resources and the Web PubSub module: error message patterns, initial interval seconds, and maximum interval seconds."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional create, read, update, and delete timeouts for all AzAPI resources and the Web PubSub module, as Go duration strings."
}
