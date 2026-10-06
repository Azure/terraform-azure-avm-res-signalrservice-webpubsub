variable "ignore_body_changes" {
  type = object({
    signalrservice_web_pub_sub                        = optional(list(string), [])
    authorization_locks                               = optional(list(string), [])
    authorization_role_assignments                    = optional(list(string), [])
    insights_diagnostic_settings                      = optional(list(string), [])
    network_private_endpoints                         = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative paths to ignore for each AzAPI resource. Paths use dot notation, cannot target individual list indices, and require Terraform 1.11 or later when non-empty. Changes take effect only after apply. Ignored configuration is not sent to Azure until the path is removed.

- `signalrservice_web_pub_sub` - Paths ignored on the Web PubSub service.
- `authorization_locks` - Paths ignored on management locks.
- `authorization_role_assignments` - Paths ignored on role assignments.
- `insights_diagnostic_settings` - Paths ignored on diagnostic settings.
- `network_private_endpoints` - Paths ignored on private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Paths ignored on private DNS zone groups.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    signalrservice_web_pub_sub                        = optional(string, "Microsoft.SignalRService/webPubSub@2024-03-01")
    authorization_locks                               = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                    = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings                      = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    network_private_endpoints                         = optional(string, "Microsoft.Network/privateEndpoints@2024-05-01")
    network_private_endpoints_private_dns_zone_groups = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions used by the module.

- `signalrservice_web_pub_sub` - Web PubSub service.
- `authorization_locks` - Management locks on the service and private endpoints.
- `authorization_role_assignments` - Role assignments on the service and private endpoints.
- `insights_diagnostic_settings` - Diagnostic settings (this resource only has preview API versions).
- `network_private_endpoints` - Private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Private DNS zone groups.
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
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module (root resource and all submodules). Defaults to `null` (no custom retry).

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
