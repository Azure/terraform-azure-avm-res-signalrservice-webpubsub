# Diagnostics example

This self-contained Azure public-cloud example deploys Web PubSub with resource logs sent to a Log Analytics workspace. It uses AzAPI for every Azure resource.

The example creates a resource group, a Log Analytics workspace in the same region as Web PubSub, and a Standard_S1 service. Its diagnostic setting sends `ConnectivityLogs`, `HttpRequestLogs`, and `MessagingLogs` to the workspace using the dedicated Log Analytics table destination. Workspace access is restricted to resource permissions, and the configured retention is 30 days.

## Run the example

Use Terraform 1.9 or later (below 2.0), and authenticate to the intended Azure subscription. The deploying identity needs permission to create the resource group, Web PubSub service, workspace, and diagnostic setting.

From `examples/diagnostics`:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The `location` input defaults to `westus3`. `tags` applies to tag-capable resources, and `enable_telemetry` controls module telemetry. `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` expose AzAPI controls. Non-empty ignored-path lists require Terraform 1.11 or later; paths use body-relative dot notation, ignored configuration is not sent to Azure, and setting changes take effect only after apply.

## Review logs

After deployment, query the `WebPubSubConnectivity`, `WebPubSubHttpRequest`, and `WebPubSubMessaging` tables in the workspace. Web PubSub resource-log export and Log Analytics ingestion/retention can incur charges; review current pricing and retention before deploying.

See [Web PubSub resource log troubleshooting](https://learn.microsoft.com/en-us/azure/azure-web-pubsub/howto-troubleshoot-resource-logs) and [supported Web PubSub log categories](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-logs/microsoft-signalrservice-webpubsub-logs).

Remove the example resources when finished:

```powershell
terraform destroy
```
