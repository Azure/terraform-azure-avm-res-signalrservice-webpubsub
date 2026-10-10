provider "azapi" {}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  location               = var.location
  name                   = "rg-webpubsub-identity-${random_string.suffix.result}"
  parent_id              = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type                   = var.resource_types.resources_resource_groups
  ignore_body_changes    = length(var.ignore_body_changes.resources_resource_groups) > 0 ? var.ignore_body_changes.resources_resource_groups : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

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

resource "azapi_resource" "user_assigned_identity" {
  location            = var.location
  name                = "id-webpubsub-${random_string.suffix.result}"
  parent_id           = azapi_resource.resource_group.id
  type                = var.resource_types.managedidentity_user_assigned_identities
  body                = {}
  ignore_body_changes = length(var.ignore_body_changes.managedidentity_user_assigned_identities) > 0 ? var.ignore_body_changes.managedidentity_user_assigned_identities : null
  response_export_values = [
    "properties.clientId",
    "properties.principalId",
  ]
  retry = var.retry
  tags  = var.tags

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

module "test" {
  source = "../../"

  location            = var.location
  name                = "wps-identity-${random_string.suffix.result}"
  parent_id           = azapi_resource.resource_group.id
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.signalrservice_web_pub_sub
  managed_identities = {
    user_assigned_resource_ids = [azapi_resource.user_assigned_identity.id]
  }
  resource_types = var.resource_types.signalrservice_web_pub_sub
  retry          = var.retry
  role_assignments = {
    workload = {
      role_definition_id_or_name = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/bfb1c7d2-fb1a-466b-b2ba-aee63b92deaf"
      principal_id               = azapi_resource.user_assigned_identity.output.properties.principalId
      principal_type             = "ServicePrincipal"
    }
  }
  tags     = var.tags
  timeouts = var.timeouts
}
