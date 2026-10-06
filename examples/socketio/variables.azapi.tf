variable "resource_types" {
  type = object({
    resources_resource_groups = optional(string, "Microsoft.Resources/resourceGroups@2024-11-01")
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
AzAPI resource type overrides. The module applies its tested API versions unless overridden.

- `resources_resource_groups` - Resource group type and API version.
- `signalrservice_web_pub_sub` - Overrides passed to the Web PubSub module.
- `signalrservice_web_pub_sub.signalrservice_web_pub_sub` - Socket.IO service.
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
    resources_resource_groups = optional(list(string), [])
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

- `resources_resource_groups` - Paths ignored on the resource group.
- `signalrservice_web_pub_sub` - Ignored-path controls passed to the Web PubSub module.
- `signalrservice_web_pub_sub.signalrservice_web_pub_sub` - Socket.IO service.
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
  description = "Optional retry configuration for the resource group and Socket.IO module."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional create, read, update, and delete timeouts for the resource group and Socket.IO module."
}
