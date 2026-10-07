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
  name                   = "rg-webpubsub-private-${random_string.suffix.result}"
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

resource "azapi_resource" "virtual_network" {
  location  = var.location
  name      = "vnet-webpubsub-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  type      = var.resource_types.network_virtual_networks
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [{
        name = "private-endpoints"
        properties = {
          addressPrefix                  = "10.0.0.0/24"
          privateEndpointNetworkPolicies = "Disabled"
        }
      }]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_virtual_networks) > 0 ? var.ignore_body_changes.network_virtual_networks : null
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

resource "azapi_resource" "private_dns_zone" {
  location               = "global"
  name                   = "privatelink.webpubsub.azure.com"
  parent_id              = azapi_resource.resource_group.id
  type                   = var.resource_types.network_private_dns_zones
  body                   = { properties = {} }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_dns_zones) > 0 ? var.ignore_body_changes.network_private_dns_zones : null
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

resource "azapi_resource" "private_dns_virtual_network_link" {
  location  = "global"
  name      = "webpubsub-vnet"
  parent_id = azapi_resource.private_dns_zone.id
  type      = var.resource_types.network_private_dns_zones_virtual_network_links
  body = {
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azapi_resource.virtual_network.id
      }
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.network_private_dns_zones_virtual_network_links) > 0 ? var.ignore_body_changes.network_private_dns_zones_virtual_network_links : null
  replace_triggers_refs = [
    "properties.virtualNetwork.id",
  ]
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

  location            = var.location
  name                = "wps-private-${random_string.suffix.result}"
  parent_id           = azapi_resource.resource_group.id
  enable_telemetry    = var.enable_telemetry
  ignore_body_changes = var.ignore_body_changes.signalrservice_web_pub_sub
  local_auth_enabled  = false
  private_endpoints = {
    primary = {
      name                          = "pe-webpubsub-${random_string.suffix.result}"
      subnet_resource_id            = "${azapi_resource.virtual_network.id}/subnets/private-endpoints"
      subresource_name              = "webpubsub"
      private_dns_zone_group_name   = "default"
      private_dns_zone_resource_ids = [azapi_resource.private_dns_zone.id]
    }
  }
  private_endpoints_manage_dns_zone_group = true
  public_network_access_enabled           = false
  resource_types                          = var.resource_types.signalrservice_web_pub_sub
  retry                                   = var.retry
  tags                                    = var.tags
  timeouts                                = var.timeouts
}
