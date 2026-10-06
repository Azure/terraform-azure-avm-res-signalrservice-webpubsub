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
  name                   = "rg-webpubsub-diagnostics-${random_string.suffix.result}"
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

resource "azapi_resource" "log_analytics_workspace" {
  location  = var.location
  name      = "law-webpubsub-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = var.resource_types.operationalinsights_workspaces
  body = {
    properties = {
      features = {
        enableLogAccessUsingOnlyResourcePermissions = true
      }
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationalinsights_workspaces) > 0 ? var.ignore_body_changes.operationalinsights_workspaces : null
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

module "test" {
  source = "../../"
  providers = {
    azapi  = azapi
    modtm  = modtm
    random = random
  }

  location  = var.location
  name      = "wps-diagnostics-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  diagnostic_settings = {
    logs = {
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = azapi_resource.log_analytics_workspace.id
      logs = [
        { category = "ConnectivityLogs" },
        { category = "HttpRequestLogs" },
        { category = "MessagingLogs" },
      ]
      metrics = [
        { category = "AllMetrics", enabled = false },
      ]
    }
  }
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.signalrservice_web_pub_sub
  resource_types      = var.resource_types.signalrservice_web_pub_sub
  retry               = var.retry
  tags                = var.tags
  timeouts            = var.timeouts
}
