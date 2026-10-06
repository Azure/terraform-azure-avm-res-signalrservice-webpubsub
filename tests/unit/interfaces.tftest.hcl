mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.SignalRService/webPubSub/wps-test"
      output = {
        properties = {
          hostName          = "wps-test.webpubsub.azure.com"
          publicPort        = 443
          serverPort        = 443
          provisioningState = "Succeeded"
          networkInterfaces = [{
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/networkInterfaces/endpoint"
          }]
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
          role_name = "Reader"
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name             = "wps-test"
  location         = "westus3"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  enable_telemetry = false
}

run "interfaces_disabled" {
  command = apply

  assert {
    condition     = length(azapi_resource.diagnostic_settings) == 0 && length(azapi_resource.role_assignments) == 0 && length(azapi_resource.lock) == 0 && length(azapi_resource.private_endpoints) == 0
    error_message = "Optional interfaces must create no resources by default."
  }
}

run "interfaces_enabled" {
  command = apply

  variables {
    tags = {
      environment = "unit"
    }
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"]
    }
    lock = {
      kind  = "ReadOnly"
      notes = "Unit test"
    }
    diagnostic_settings = {
      logs = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.OperationalInsights/workspaces/test"
        logs = [{
          category_group = "allLogs"
        }]
        metrics = [{
          category = "AllMetrics"
        }]
      }
    }
    role_assignments = {
      reader = {
        name                       = "00000000-0000-0000-0000-000000000003"
        role_definition_id_or_name = "Reader"
        principal_id               = "00000000-0000-0000-0000-000000000004"
        principal_type             = "ServicePrincipal"
      }
    }
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/test/subnets/endpoint"
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.webpubsub.azure.com",
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/other.example"
        ]
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
          }
        }
        role_assignments = {
          reader = {
            name                       = "00000000-0000-0000-0000-000000000005"
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000004"
          }
        }
      }
      unlocked = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/test/subnets/endpoint"
        lock = {
          kind = "None"
        }
        tags = {}
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

  assert {
    condition     = azapi_resource.this.identity[0].type == "UserAssigned" && length(azapi_resource.this.identity[0].identity_ids) == 1
    error_message = "The configured user-assigned identity must reach the primary service."
  }

  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "ReadOnly" && azapi_resource.lock[0].body.properties.notes == "Unit test"
    error_message = "The service lock must preserve its kind and notes."
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["logs"].body.properties.logs[0].categoryGroup == "allLogs" && azapi_resource.diagnostic_settings["logs"].body.properties.metrics[0].category == "AllMetrics"
    error_message = "Diagnostic settings must use the v2 logs and metrics schema."
  }

  assert {
    condition     = azapi_resource.role_assignments["reader"].name == "00000000-0000-0000-0000-000000000003" && azapi_resource.role_assignments["reader"].parent_id == azapi_resource.this.id
    error_message = "Role assignments must use the requested name and service scope."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].parent_id == var.parent_id && azapi_resource.private_endpoints["primary"].body.properties.privateLinkServiceConnections[0].properties.groupIds[0] == "webpubsub" && azapi_resource.private_endpoints["primary"].body.properties.ipConfigurations[0].properties.memberName == "webpubsub"
    error_message = "Private endpoints must default to the service resource group and Web PubSub group/member names."
  }

  assert {
    condition     = length(azapi_resource.private_dns_zone_groups) == 1 && length(toset([for zone in azapi_resource.private_dns_zone_groups["primary"].body.properties.privateDnsZoneConfigs : zone.name])) == 2
    error_message = "DNS zone groups must only be created with zones and have unique configuration names."
  }

  assert {
    condition     = length(azapi_resource.private_endpoint_locks) == 1 && length(azapi_resource.private_endpoint_role_assignments) == 1
    error_message = "Private endpoint locks must inherit unless opted out; nested role assignments must be created."
  }

  assert {
    condition     = azapi_resource.private_endpoints["primary"].tags.environment == "unit" && length(azapi_resource.private_endpoints["unlocked"].tags) == 0
    error_message = "Private endpoints must inherit tags unless an explicit replacement is supplied."
  }

  assert {
    condition     = alltrue([for resource in azapi_resource.private_endpoints : resource.retry.interval_seconds == 5 && resource.timeouts.create == "45m"]) && azapi_resource.diagnostic_settings["logs"].retry.interval_seconds == 5
    error_message = "AzAPI operation controls must reach interface resources."
  }

  assert {
    condition     = length(output.private_endpoints) == 2 && length(output.diagnostic_settings) == 1 && output.lock_resource_id != null
    error_message = "Interface outputs must expose the created resources."
  }
}

run "externally_managed_dns" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      primary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/test/subnets/endpoint"
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.webpubsub.azure.com"
        ]
      }
    }
  }

  assert {
    condition     = length(azapi_resource.private_endpoints) == 1 && length(azapi_resource.private_dns_zone_groups) == 0
    error_message = "External DNS management must suppress zone groups without suppressing private endpoints."
  }
}
