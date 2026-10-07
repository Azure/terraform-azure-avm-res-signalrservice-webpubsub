# Socket.IO example

This self-contained Azure public-cloud example deploys an Azure Web PubSub service configured for Socket.IO, using AzAPI for every Azure resource.

The service uses the `SocketIO` kind with `Serverless` service mode and the Standard tier. Public network access is enabled for client connectivity, while local access-key authentication is disabled so applications must use Microsoft Entra ID. This example creates no client application or Socket.IO workload.

## Run the example

Use Terraform 1.9 or later (below 2.0), and authenticate to the intended Azure subscription. The deploying identity needs permission to create the resource group and Web PubSub service.

From `examples/socketio`:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The `location` input defaults to `westus3`. `tags` applies to tag-capable resources, and `enable_telemetry` controls module telemetry. `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` expose AzAPI controls. Non-empty ignored-path lists require Terraform 1.11 or later; paths use body-relative dot notation, ignored configuration is not sent to Azure, and setting changes take effect only after apply.

## Connect an application

Configure a Socket.IO application to connect to the output `hostname` and use Microsoft Entra ID authentication with an identity granted the appropriate Web PubSub data-plane role. Public access is enabled in this example; production deployments should restrict network access to trusted clients or use private connectivity. Identity or role configuration alone does not provide network connectivity.

Socket.IO, Web PubSub, and outbound messages can incur Azure charges. Remove the example resources when finished:

```powershell
terraform destroy
```
