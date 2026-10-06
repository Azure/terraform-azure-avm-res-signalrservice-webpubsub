mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.SignalRService/webPubSub/wps-example"
      output = {
        properties = {
          hostName          = "wps-example.webpubsub.azure.com"
          publicPort        = 443
          serverPort        = 443
          provisioningState = "Succeeded"
        }

      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          role_name = "Web PubSub Service Reader"
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/bfb1c7d2-fb1a-466b-b2ba-aee63b92deaf"
        }]
      }
    }
  }
}

mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "azapitst"
    }
  }
}

mock_provider "modtm" {}

run "default" {
  command = apply

  module {
    source = "./examples/default"
  }

  variables {
    enable_telemetry = false
    tags = {
      environment = "unit"
    }
    resource_types = {
      signalrservice_web_pub_sub = {
        signalrservice_web_pub_sub = "Microsoft.SignalRService/webPubSub@2024-03-01"
      }
    }
    retry = {
      error_message_regex = ["ScopeLocked"]
      interval_seconds    = 5
    }
    timeouts = {
      create = "45m"
    }
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", output.resource_group_id)) && can(provider::azapi::parse_resource_id("Microsoft.SignalRService/webPubSub", output.resource_id))
    error_message = "The example must expose separate resource group and Web PubSub resource IDs."
  }

  assert {
    condition     = output.name == "wps-azapitst" && output.hostname == "wps-example.webpubsub.azure.com"
    error_message = "The example must expose the generated service name and returned hostname."
  }

  assert {
    condition     = output.public_port == 443 && output.server_port == 443 && output.provisioning_state == "Succeeded"
    error_message = "The example must expose service ports and provisioning state."
  }

  assert {
    condition     = azapi_resource.resource_group.tags.environment == "unit" && azapi_resource.resource_group.retry.interval_seconds == 5 && azapi_resource.resource_group.timeouts.create == "45m"
    error_message = "The example must apply tags and operation controls to its resource group."
  }
}

run "private" {
  command = apply

  module {
    source = "./examples/private_endpoint"
  }

  variables {
    enable_telemetry = false
    tags = {
      environment = "unit"
    }
    retry = {
      error_message_regex = ["ScopeLocked"]
      interval_seconds    = 5
    }
    timeouts = {
      create = "45m"
    }
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }
  override_resource {
    target = azapi_resource.virtual_network
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/virtualNetworks/example"
    }
  }
  override_resource {
    target = azapi_resource.private_dns_zone
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.webpubsub.azure.com"
    }
  }
  override_resource {
    target = azapi_resource.private_dns_virtual_network_link
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateDnsZones/privatelink.webpubsub.azure.com/virtualNetworkLinks/webpubsub-vnet"
    }
  }
  override_resource {
    target = module.test.azapi_resource.private_endpoints["primary"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/endpoint"
      output = {
        properties = {
          networkInterfaces = [{
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/networkInterfaces/endpoint"
          }]
        }
      }
    }
  }
  override_resource {
    target = module.test.azapi_resource.private_dns_zone_groups["primary"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Network/privateEndpoints/endpoint/privateDnsZoneGroups/default"
    }
  }

  assert {
    condition     = azapi_resource.virtual_network.body.properties.subnets[0].properties.privateEndpointNetworkPolicies == "Disabled" && output.subnet_resource_id == "${output.virtual_network_resource_id}/subnets/private-endpoints"
    error_message = "The example must provide a dedicated private endpoint subnet with private endpoint network policies disabled."
  }

  assert {
    condition     = azapi_resource.private_dns_zone.name == "privatelink.webpubsub.azure.com" && azapi_resource.private_dns_virtual_network_link.body.properties.virtualNetwork.id == output.virtual_network_resource_id && !azapi_resource.private_dns_virtual_network_link.body.properties.registrationEnabled
    error_message = "The private DNS zone must be linked to the example VNet with auto-registration disabled."
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/privateEndpoints", output.private_endpoint_resource_id)) && can(provider::azapi::parse_resource_id("Microsoft.Network/privateEndpoints/privateDnsZoneGroups", output.private_dns_zone_group_resource_id)) && length(output.private_endpoint_network_interface_resource_ids) == 1
    error_message = "The module must create and expose the private endpoint, NIC, and DNS zone group."
  }

  assert {
    condition     = module.test.private_endpoints["primary"].name == "pe-webpubsub-azapitst" && output.hostname == "wps-example.webpubsub.azure.com"
    error_message = "The endpoint must use the requested name and retain the normal service hostname."
  }

  assert {
    condition     = azapi_resource.virtual_network.tags.environment == "unit" && azapi_resource.private_dns_zone.retry.interval_seconds == 5 && azapi_resource.private_dns_virtual_network_link.timeouts.create == "45m"
    error_message = "Tags and operation controls must reach the supporting network resources."
  }
}

run "socketio" {
  command = apply

  module {
    source = "./examples/socketio"
  }

  variables {
    enable_telemetry = false
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }

  assert {
    condition     = output.service_mode == "Serverless" && can(provider::azapi::parse_resource_id("Microsoft.SignalRService/webPubSub", output.resource_id))
    error_message = "The example must expose a Socket.IO service configured in Serverless mode."
  }
}

run "diagnostics" {
  command = apply

  module {
    source = "./examples/diagnostics"
  }

  variables {
    enable_telemetry = false
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }
  override_resource {
    target = azapi_resource.log_analytics_workspace
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.OperationalInsights/workspaces/example"
    }
  }
  override_resource {
    target = module.test.azapi_resource.diagnostic_settings["logs"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.Insights/diagnosticSettings/example"
    }
  }

  assert {
    condition     = azapi_resource.log_analytics_workspace.body.properties.sku.name == "PerGB2018" && azapi_resource.log_analytics_workspace.body.properties.retentionInDays == 30 && azapi_resource.log_analytics_workspace.body.properties.features.enableLogAccessUsingOnlyResourcePermissions
    error_message = "The example must create a 30-day Log Analytics workspace with resource-only access."
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Insights/diagnosticSettings", output.diagnostic_setting_resource_id))
    error_message = "The module must create and expose its diagnostic setting."
  }
}

run "identity_rbac" {
  command = apply

  module {
    source = "./examples/identity_rbac"
  }

  variables {
    enable_telemetry = false
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }
  override_resource {
    target = azapi_resource.user_assigned_identity
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.ManagedIdentity/userAssignedIdentities/example"
      output = {
        properties = {
          clientId    = "00000000-0000-0000-0000-000000000002"
          principalId = "00000000-0000-0000-0000-000000000003"
        }
      }
    }
  }
  override_resource {
    target = module.test.azapi_resource.role_assignments["workload"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.SignalRService/webPubSub/wps/providers/Microsoft.Authorization/roleAssignments/00000000-0000-0000-0000-000000000004"
    }
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", output.user_assigned_identity_resource_id)) && output.user_assigned_identity_client_id == "00000000-0000-0000-0000-000000000002"
    error_message = "The example must create and expose its user-assigned identity."
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Authorization/roleAssignments", output.role_assignment_resource_id))
    error_message = "The example must create and expose the Web PubSub Service Reader role assignment."
  }
}
