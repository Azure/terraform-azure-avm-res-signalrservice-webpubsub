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
