mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.SignalRService/webPubSub/wps-test"
    output = {
      properties = {
        hostName          = "wps-test.webpubsub.azure.com"
        publicPort        = 443
        serverPort        = 443
        provisioningState = "Succeeded"
      }
      identity = {
        principalId = "00000000-0000-0000-0000-000000000002"
        tenantId    = "00000000-0000-0000-0000-000000000001"
      }
    }
  }
}

variables {
  name             = "wps-test"
  location         = "westus3"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  enable_telemetry = false
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.SignalRService/webPubSub@2024-03-01" && azapi_resource.this.parent_id == var.parent_id
    error_message = "The module must deploy Web PubSub in the supplied resource group, not create a resource group."
  }

  assert {
    condition     = azapi_resource.this.body.kind == "WebPubSub" && azapi_resource.this.body.sku.name == "Standard_S1"
    error_message = "The default service must be Standard_S1 WebPubSub."
  }

  assert {
    condition     = azapi_resource.this.body.properties.disableLocalAuth && !azapi_resource.this.body.properties.disableAadAuth && azapi_resource.this.body.properties.publicNetworkAccess == "Disabled"
    error_message = "Defaults must use Entra authentication with public access and local authentication disabled."
  }

  assert {
    condition     = !contains(keys(azapi_resource.this.body.properties), "socketIO") && !contains(keys(azapi_resource.this.body.properties), "networkACLs")
    error_message = "Unconfigured optional properties must not be sent to Azure."
  }

  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == var.name && output.hostname == "wps-test.webpubsub.azure.com" && output.public_port == 443 && output.server_port == 443 && output.provisioning_state == "Succeeded"
    error_message = "Outputs must map to the deployed Web PubSub service."
  }

  assert {
    condition     = output.system_assigned_mi_principal_id == null
    error_message = "Disabled system-assigned identity must return null."
  }
}

run "configured_service" {
  command = apply

  variables {
    kind                          = "SocketIO"
    socket_io_service_mode        = "Serverless"
    public_network_access_enabled = true
    local_auth_enabled            = true
    aad_auth_enabled              = false
    client_certificate_enabled    = true
    resource_stopped              = true
    sku = {
      name     = "Premium_P1"
      capacity = 20
    }
    managed_identities = {
      system_assigned = true
    }
    live_trace_configuration = {
      enabled = true
      categories = [{
        name    = "ConnectivityLogs"
        enabled = false
      }]
    }
    resource_log_configuration = {
      categories = [{
        name = "MessagingLogs"
      }]
    }
    network_acls = {
      default_action = "Deny"
      public_network = {
        allow = ["RESTAPI"]
      }
      private_endpoints = [{
        name  = "endpoint-connection"
        allow = ["ClientConnection", "ServerConnection"]
      }]
      ip_rules = [{
        action = "Allow"
        value  = "192.0.2.0/24"
      }]
    }
    tags = {
      environment = "unit"
    }
    resource_types = {
      signalrservice_web_pub_sub = "Microsoft.SignalRService/webPubSub@2024-10-01-preview"
    }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 5
      max_interval_seconds = 30
    }
    timeouts = {
      create = "45m"
      read   = "5m"
      update = "45m"
      delete = "45m"
    }
    ignore_body_changes = {
      signalrservice_web_pub_sub = ["sku.capacity"]
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.socketIO.serviceMode == "Serverless" && azapi_resource.this.body.properties.resourceStopped == "true"
    error_message = "Socket.IO mode and stopped state must map to the ARM schema."
  }

  assert {
    condition     = azapi_resource.this.body.properties.disableAadAuth && !azapi_resource.this.body.properties.disableLocalAuth && azapi_resource.this.body.properties.publicNetworkAccess == "Enabled" && azapi_resource.this.body.properties.tls.clientCertEnabled
    error_message = "Authentication, network, and TLS overrides must be honored."
  }

  assert {
    condition     = azapi_resource.this.body.properties.liveTraceConfiguration.enabled == "true" && azapi_resource.this.body.properties.liveTraceConfiguration.categories[0].enabled == "false" && azapi_resource.this.body.properties.resourceLogConfiguration.categories[0].enabled == "true"
    error_message = "Trace and resource log enabled flags must use ARM string values."
  }

  assert {
    condition     = azapi_resource.this.body.properties.networkACLs.ipRules[0].value == "192.0.2.0/24" && azapi_resource.this.body.properties.networkACLs.privateEndpoints[0].name == "endpoint-connection"
    error_message = "Network ACLs must preserve IP rules and private endpoint connection names."
  }

  assert {
    condition     = azapi_resource.this.type == var.resource_types.signalrservice_web_pub_sub && azapi_resource.this.retry.interval_seconds == 5 && azapi_resource.this.timeouts.create == "45m" && azapi_resource.this.tags.environment == "unit"
    error_message = "Resource type, retry, timeouts, and tags must propagate to the resource."
  }

  assert {
    condition     = output.system_assigned_mi_principal_id == "00000000-0000-0000-0000-000000000002"
    error_message = "System-assigned identity output must map to Azure's response."
  }
}

run "premium_p2_default_capacity" {
  command = apply

  variables {
    sku = {
      name = "Premium_P2"
    }
  }

  assert {
    condition     = !contains(keys(azapi_resource.this.body.sku), "capacity")
    error_message = "Omitted capacity must leave the SKU-specific default to Azure."
  }

}

run "invalid_kind" {
  command = plan
  variables {
    kind = "Invalid"
  }
  expect_failures = [var.kind]
}

run "invalid_socket_io_mode" {
  command = plan
  variables {
    socket_io_service_mode = "Invalid"
  }
  expect_failures = [var.socket_io_service_mode]
}

run "unsupported_combined_identities" {
  command = plan
  variables {
    managed_identities = {
      system_assigned = true
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"
      ]
    }
  }
  expect_failures = [azapi_resource.this]
}

run "unsupported_multiple_user_identities" {
  command = plan
  variables {
    managed_identities = {
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/first",
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/second"
      ]
    }
  }
  expect_failures = [azapi_resource.this]
}

run "invalid_name" {
  command = plan
  variables {
    name = "1-invalid"
  }
  expect_failures = [var.name]
}

run "invalid_parent" {
  command = plan
  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }
  expect_failures = [var.parent_id]
}

run "invalid_capacity" {
  command = plan
  variables {
    sku = {
      name     = "Premium_P2"
      capacity = 1
    }
  }
  expect_failures = [var.sku]
}

run "invalid_network_action" {
  command = plan
  variables {
    network_acls = {
      default_action = "Invalid"
    }
  }
  expect_failures = [var.network_acls]
}

run "invalid_request_type" {
  command = plan
  variables {
    network_acls = {
      public_network = {
        allow = ["Invalid"]
      }
    }
  }
  expect_failures = [var.network_acls]
}

run "free_client_certificate" {
  command = plan
  variables {
    sku = {
      name = "Free_F1"
    }
    client_certificate_enabled = true
  }
  expect_failures = [var.client_certificate_enabled]
}
