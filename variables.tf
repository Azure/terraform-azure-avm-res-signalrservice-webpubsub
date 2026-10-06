variable "location" {
  type        = string
  description = "The Azure region where the Web PubSub service will be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The globally unique name of the Web PubSub service."
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.name))
    error_message = "The name must be 3 to 63 characters, start with a letter, end with a letter or digit, and contain only letters, digits, and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = "The fully-qualified ARM resource ID of the existing resource group in which to deploy the Web PubSub service. This module does not create the resource group."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure resource group resource ID."
  }
}

variable "aad_auth_enabled" {
  type        = bool
  default     = true
  description = "Whether Microsoft Entra ID authentication is enabled."
  nullable    = false
}

variable "client_certificate_enabled" {
  type        = bool
  default     = false
  description = "Whether to request a client certificate during the TLS handshake. This feature is not supported by Free_F1."
  nullable    = false

  validation {
    condition     = !var.client_certificate_enabled || var.sku.name != "Free_F1"
    error_message = "Client certificates are not supported by the Free_F1 SKU."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "kind" {
  type        = string
  default     = "WebPubSub"
  description = "The service kind: WebPubSub or SocketIO. Changing the kind replaces the service."
  nullable    = false

  validation {
    condition     = contains(["WebPubSub", "SocketIO"], var.kind)
    error_message = "The kind must be WebPubSub or SocketIO."
  }
}

variable "live_trace_configuration" {
  type = object({
    enabled = optional(bool, false)
    categories = optional(list(object({
      name    = string
      enabled = optional(bool, true)
    })), [])
  })
  default     = null
  description = "Optional live trace configuration. `enabled` enables live trace connections; `categories` contains category names and enabled flags."
}

variable "local_auth_enabled" {
  type        = bool
  default     = false
  description = "Whether access-key authentication is enabled. Disabled by default; use Microsoft Entra ID authentication."
  nullable    = false
}

variable "network_acls" {
  type = object({
    default_action = optional(string, "Deny")
    public_network = optional(object({
      allow = optional(set(string), [])
      deny  = optional(set(string), [])
    }), {})
    private_endpoints = optional(list(object({
      name  = string
      allow = optional(set(string), [])
      deny  = optional(set(string), [])
    })), [])
    ip_rules = optional(list(object({
      action = string
      value  = string
    })), [])
  })
  default     = null
  description = <<DESCRIPTION
Optional network access controls. `default_action` is Allow or Deny; `public_network` and named `private_endpoints` specify allowed or denied request types (ClientConnection, ServerConnection, RESTAPI, Trace). `private_endpoints[*].name` is the private endpoint connection name, not a resource ID. `ip_rules` contains Allow/Deny actions and IP addresses, CIDRs, or service tags.
DESCRIPTION

  validation {
    condition = var.network_acls == null ? true : (
      contains(["Allow", "Deny"], var.network_acls.default_action) &&
      alltrue([for rule in var.network_acls.ip_rules : contains(["Allow", "Deny"], rule.action)])
    )
    error_message = "Network ACL default_action and IP rule actions must be Allow or Deny."
  }
  validation {
    condition = var.network_acls == null ? true : alltrue([
      for request_type in concat(
        tolist(var.network_acls.public_network.allow),
        tolist(var.network_acls.public_network.deny),
        flatten([for endpoint in var.network_acls.private_endpoints : concat(tolist(endpoint.allow), tolist(endpoint.deny))])
      ) : contains(["ClientConnection", "ServerConnection", "RESTAPI", "Trace"], request_type)
    ])
    error_message = "Network ACL request types must be ClientConnection, ServerConnection, RESTAPI, or Trace."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "Whether public network access is enabled. Disabled by default; configure a private endpoint for data-plane access."
  nullable    = false
}

variable "region_endpoint_enabled" {
  type        = bool
  default     = true
  description = "Whether new connections are routed to the regional endpoint. Disabling this requires an existing replica."
  nullable    = false
}

variable "resource_log_configuration" {
  type = object({
    categories = list(object({
      name    = string
      enabled = optional(bool, true)
    }))
  })
  default     = null
  description = "Optional resource log configuration containing category names and enabled flags. Diagnostic settings route these logs to their destinations."
}

variable "resource_stopped" {
  type        = bool
  default     = false
  description = "Whether to stop the service's data plane."
  nullable    = false
}

variable "sku" {
  type = object({
    name     = optional(string, "Standard_S1")
    capacity = optional(number)
  })
  default     = {}
  description = "The service SKU: `name` is Free_F1, Standard_S1, Premium_P1, or Premium_P2. Optional `capacity` is the unit count; Azure defaults to 1, or 100 for Premium_P2."
  nullable    = false

  validation {
    condition     = contains(["Free_F1", "Standard_S1", "Premium_P1", "Premium_P2"], var.sku.name)
    error_message = "The SKU name must be Free_F1, Standard_S1, Premium_P1, or Premium_P2."
  }
  validation {
    condition = var.sku.capacity == null ? true : (
      var.sku.name == "Free_F1" ? var.sku.capacity == 1 :
      var.sku.name == "Premium_P2" ? contains(range(100, 1001, 100), var.sku.capacity) :
      contains(concat(range(1, 11), range(20, 101, 10)), var.sku.capacity)
    )
    error_message = "Capacity must be 1 for Free_F1; 1-10 or a multiple of 10 up to 100 for Standard_S1/Premium_P1; or a multiple of 100 from 100 to 1000 for Premium_P2."
  }
}

variable "socket_io_service_mode" {
  type        = string
  default     = "Default"
  description = "The Socket.IO service mode, Default or Serverless. Only sent when kind is SocketIO."
  nullable    = false

  validation {
    condition     = contains(["Default", "Serverless"], var.socket_io_service_mode)
    error_message = "The Socket.IO service mode must be Default or Serverless."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
