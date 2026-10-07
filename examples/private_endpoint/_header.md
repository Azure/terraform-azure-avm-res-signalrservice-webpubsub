# Private endpoint example

This self-contained Azure public-cloud example deploys Web PubSub with private connectivity using AzAPI for every Azure resource.

The example creates a resource group, a VNet (`10.0.0.0/16`) with a dedicated private endpoint subnet (`10.0.0.0/24`), the `privatelink.webpubsub.azure.com` private DNS zone, and a DNS link to the VNet with auto-registration disabled. Private endpoint network policies are disabled on the dedicated subnet.

The Web PubSub module creates a Standard_S1 service, a private endpoint targeting the `webpubsub` subresource, and a private DNS zone group. The zone group manages the endpoint's DNS records; do not add a separate A record. The `primary` map key is deliberately static so it is known during planning.

Public network access and local access-key authentication remain disabled. Microsoft Entra ID authentication is enabled. No workload, application identity, or data-plane role assignment is created by this networking example.

## Run the example

Use Terraform 1.9 or later (below 2.0), and authenticate to the intended Azure subscription. The deploying identity needs permission to create the resource group, Web PubSub, networking, private DNS, and private endpoint connections, including approval on the Web PubSub resource.

From `examples/private_endpoint`:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The `location` input defaults to `westus3`. `tags` propagates to tag-capable resources, including the private endpoint. `enable_telemetry` controls module telemetry. `retry` and `timeouts` apply to all resources; `resource_types` and `ignore_body_changes` expose per-resource controls and nested module overrides. Non-empty ignored-path lists require Terraform 1.11 or later; paths use body-relative dot notation, ignored configuration is not sent to Azure, and setting changes take effect only after apply.

## Connect privately

Connect from a workload with network access to this VNet and private DNS resolution. Use the normal hostname returned by `hostname`, not its `privatelink` subdomain. Azure DNS resolves that hostname to the endpoint's private IP from the linked VNet. Custom or on-premises DNS requires forwarding to an Azure resolver with access to the private zone.

Grant the appropriate Web PubSub data-plane role to the application's Microsoft Entra ID identity before connecting. A private endpoint provides network access, not authentication or authorization. There is no client VM or public IP in this example; deploying it does not give your local computer a route into the VNet.

See [Web PubSub private endpoint guidance](https://learn.microsoft.com/en-us/azure/azure-web-pubsub/howto-secure-private-endpoints) for DNS and connectivity details.

Web PubSub, Private Link, and private DNS incur Azure charges. Remove the example resources when finished:

```powershell
terraform destroy
```
