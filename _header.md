# SignalR Service Web PubSub

AVM Terraform resource module for SignalR Service Web PubSub.

Deploys `Microsoft.SignalRService/webPubSub` using `Azure/azapi ~> 2.12` and the stable `2024-03-01` API. The module supports Web PubSub and Socket.IO, SKU scaling, authentication, TLS client certificates, network ACLs, live tracing, resource logs, managed identities, diagnostic settings, role assignments, locks, and private endpoints.

Supply the ARM ID of an existing resource group as `parent_id`. The module does not create the resource group. Public network access and local access-key authentication are disabled by default. Use Microsoft Entra ID authentication and configure a private endpoint, or explicitly enable public access when needed. The private endpoint group ID is `webpubsub`; the public-cloud private DNS zone is `privatelink.webpubsub.azure.com`.

Web PubSub supports at most one managed identity: either a system-assigned identity or one user-assigned identity. The module rejects multiple identity configurations before deployment.

```hcl
module "webpubsub" {
  source = "Azure/avm-res-signalrservice-webpubsub/azure"

  name      = "my-unique-webpubsub"
  location  = "westus3"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"

  sku = {
    name     = "Standard_S1"
    capacity = 1
  }
}
```

`resource_types` allows API-version overrides. `retry` and `timeouts` configure resource operations. `ignore_body_changes` accepts body-relative dot-notation paths per resource; non-empty lists require Terraform 1.11 or later. Ignored configuration is not sent to Azure and changes to this setting take effect only after apply.

The implementation follows the [Microsoft Learn Web PubSub AzAPI reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.signalrservice/2024-03-01/webpubsub?pivots=deployment-language-terraform). Preview-only properties such as application firewall rules are not included in the stable API.

## Existing scaffold state

The previous scaffold created a resource group at `azapi_resource.this`; it did not create Web PubSub. That state cannot be converted into a Web PubSub service. Before upgrading an applied scaffold, back up state and transfer the resource group to its owning configuration, or remove it from this module's state without destroying it:

```powershell
terraform state pull | Set-Content -Path .\state-backup.json
terraform state rm 'module.webpubsub.azapi_resource.this'
```

Replace `module.webpubsub` with the actual module address, retain the resource group in its owning configuration, and supply its ID as `parent_id`. Do not apply a replacement plan against the old resource-group state; deleting that resource group can delete its contents.
