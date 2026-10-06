resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.signalrservice_web_pub_sub
  body = {
    kind = var.kind
    sku = merge({
      name = var.sku.name
      }, var.sku.capacity == null ? {} : {
      capacity = var.sku.capacity
    })
    properties = merge({
      disableAadAuth        = !var.aad_auth_enabled
      disableLocalAuth      = !var.local_auth_enabled
      publicNetworkAccess   = var.public_network_access_enabled ? "Enabled" : "Disabled"
      regionEndpointEnabled = var.region_endpoint_enabled ? "Enabled" : "Disabled"
      resourceStopped       = var.resource_stopped ? "true" : "false"
      tls = {
        clientCertEnabled = var.client_certificate_enabled
      }
      }, var.live_trace_configuration == null ? {} : {
      liveTraceConfiguration = {
        enabled = tostring(var.live_trace_configuration.enabled)
        categories = [
          for category in var.live_trace_configuration.categories : {
            name    = category.name
            enabled = tostring(category.enabled)
          }
        ]
      }
      }, var.resource_log_configuration == null ? {} : {
      resourceLogConfiguration = {
        categories = [
          for category in var.resource_log_configuration.categories : {
            name    = category.name
            enabled = tostring(category.enabled)
          }
        ]
      }
      }, var.network_acls == null ? {} : {
      networkACLs = {
        defaultAction = var.network_acls.default_action
        publicNetwork = {
          allow = var.network_acls.public_network.allow
          deny  = var.network_acls.public_network.deny
        }
        privateEndpoints = [
          for endpoint in var.network_acls.private_endpoints : {
            name  = endpoint.name
            allow = endpoint.allow
            deny  = endpoint.deny
          }
        ]
        ipRules = [
          for rule in var.network_acls.ip_rules : {
            action = rule.action
            value  = rule.value
          }
        ]
      }
      }, var.kind == "SocketIO" ? {
      socketIO = {
        serviceMode = var.socket_io_service_mode
      }
    } : {})
  }
  ignore_body_changes = length(var.ignore_body_changes.signalrservice_web_pub_sub) > 0 ? var.ignore_body_changes.signalrservice_web_pub_sub : null
  replace_triggers_refs = [
    "kind",
  ]
  response_export_values = [
    "properties.hostName",
    "properties.publicPort",
    "properties.serverPort",
    "properties.provisioningState",
    "identity.principalId",
    "identity.tenantId",
  ]
  retry = var.retry
  tags  = var.tags

  dynamic "identity" {
    for_each = module.avm_interfaces.managed_identities_azapi == null ? [] : [module.avm_interfaces.managed_identities_azapi]
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = (var.managed_identities.system_assigned ? 1 : 0) + length(var.managed_identities.user_assigned_resource_ids) <= 1
      error_message = "Web PubSub supports at most one managed identity: either a system-assigned identity or one user-assigned identity."
    }
  }
}
