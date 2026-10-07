module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  diagnostic_settings_v2                  = var.diagnostic_settings
  enable_telemetry                        = var.enable_telemetry
  lock                                    = var.lock
  managed_identities                      = var.managed_identities
  private_endpoints                       = local.interface_private_endpoints
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = azapi_resource.this.id
  role_assignment_definition_scope        = azapi_resource.this.id
  role_assignments = {
    for key, assignment in var.role_assignments : key => merge(assignment, {
      principal_type = assignment.principal_type != null ? assignment.principal_type : (assignment.skip_service_principal_aad_check ? "ServicePrincipal" : null)
    })
  }
}

resource "azapi_resource" "diagnostic_settings" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi_v2

  name                   = coalesce(each.value.name, "diag-${var.name}-${substr(uuidv5("url", each.key), 0, 8)}")
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.insights_diagnostic_settings
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  type                = var.resource_types.authorization_role_assignments
  body                = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoints" {
  for_each = module.avm_interfaces.private_endpoints_azapi

  location = coalesce(var.private_endpoints[each.key].location, var.location)
  name     = each.value.name
  parent_id = coalesce(
    var.private_endpoints[each.key].resource_group_name,
    var.parent_id,
  )
  type                = var.resource_types.network_private_endpoints
  body                = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  replace_triggers_refs = [
    "properties.subnet.id",
    "properties.privateLinkServiceConnections",
    "properties.customNetworkInterfaceName",
    "properties.ipConfigurations",
  ]
  response_export_values = ["properties.networkInterfaces"]
  retry                  = var.retry
  # TFFR9 permits endpoint tag overrides; remove when the managed ruleset accepts them.
  # tflint-ignore: avm_azapi_resource_tags_required
  tags = var.private_endpoints[each.key].tags != null ? var.private_endpoints[each.key].tags : var.tags

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
      condition     = var.private_endpoints[each.key].resource_group_name == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.private_endpoints[each.key].resource_group_name))
      error_message = "`private_endpoints[*].resource_group_name` must be a fully-qualified resource group resource ID, or null."
    }
    precondition {
      condition     = local.interface_private_endpoints[each.key].subresource_name == "webpubsub"
      error_message = "`private_endpoints[*].subresource_name` must be `webpubsub`, or null to use that default."
    }
    precondition {
      condition     = var.private_endpoints[each.key].lock == null ? true : contains(["None", "CanNotDelete", "ReadOnly"], var.private_endpoints[each.key].lock.kind)
      error_message = "`private_endpoints[*].lock.kind` must be `None`, `CanNotDelete`, or `ReadOnly`."
    }
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = {
    for key, group in module.avm_interfaces.private_dns_zone_groups_azapi : key => group
    if length(var.private_endpoints[key].private_dns_zone_resource_ids) > 0
  }

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  # The utility repeats the group name for each zone; Azure requires unique config names.
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for index, config in each.value.body.properties.privateDnsZoneConfigs : merge(config, {
          name = "zone-${index}"
        })
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

  name                = each.value.name
  parent_id           = azapi_resource.private_endpoints[each.value.pe_key].id
  type                = var.resource_types.authorization_role_assignments
  body                = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.avm_interfaces.lock_private_endpoint_azapi

  name                   = coalesce(each.value.name, "lock-${each.value.body.properties.level}")
  parent_id              = azapi_resource.private_endpoints[each.value.pe_key].id
  type                   = var.resource_types.authorization_locks
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments,
  ]
}

resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name                   = coalesce(module.avm_interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.authorization_locks
  body                   = module.avm_interfaces.lock_azapi.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignments,
    azapi_resource.private_endpoints,
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments,
    azapi_resource.private_endpoint_locks,
  ]
}
