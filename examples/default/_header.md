# Default example

This example creates a resource group with AzAPI and passes its ARM ID as `parent_id` to the local Web PubSub module. A random suffix makes the resource group and service names unique.

The module uses `Microsoft.SignalRService/webPubSub@2024-03-01` and its default `WebPubSub` kind and `Standard_S1` SKU. Capacity is omitted so Azure uses its default of one unit. Microsoft Entra ID authentication is enabled; public network access and local access-key authentication are disabled.

This is a minimal infrastructure example, not a connected application. It does not create a private endpoint, DNS zone, managed identity, or data-plane role assignments. Configure a private endpoint and private DNS, and grant the appropriate Web PubSub data-plane role to your application's identity before connecting. The hostname output alone does not make the service publicly accessible.

## Run the example

Use Terraform 1.9 or later (below 2.0) and authenticate to the intended Azure subscription, for example with `az login` and `az account set --subscription <subscription-id>`. The caller must be able to create resource groups and Web PubSub resources.

From `examples/default`:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The `location` input defaults to `westus3`. Supply `-var="location=<region>"` during planning to select another supported region. `tags` applies to both the resource group and service; `enable_telemetry` controls module telemetry.

`retry` and `timeouts` apply to both the resource group and module. `resource_types.resources_resource_groups` controls the resource group API version; the nested `resource_types.signalrservice_web_pub_sub` object passes module API-version overrides through unchanged. `ignore_body_changes` follows the same nesting and accepts body-relative dot-notation paths; non-empty lists require Terraform 1.11 or later. Ignored configuration is not sent to Azure and setting changes take effect only after apply.

Outputs expose the resource group ID, service ID and name, hostname, client/server ports, and provisioning state. No access keys are exported.

The Standard SKU incurs Azure charges. Remove the example resources when finished:

```powershell
terraform destroy
```
