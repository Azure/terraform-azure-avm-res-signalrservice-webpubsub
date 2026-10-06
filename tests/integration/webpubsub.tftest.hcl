run "deploy_webpubsub" {
  command = apply

  module {
    source = "./examples/default"
  }

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.SignalRService/webPubSub", output.resource_id))
    error_message = "The example must return a valid Web PubSub service resource ID."
  }

  assert {
    condition     = length(output.hostname) > 0
    error_message = "Azure must return the deployed service hostname."
  }
}
