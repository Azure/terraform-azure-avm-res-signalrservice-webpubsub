# Identity and RBAC example

This self-contained Azure public-cloud example deploys Web PubSub with a user-assigned managed identity and a data-plane RBAC assignment. AzAPI manages the resource group, identity, Web PubSub service, and role assignment.

The identity is attached to the Standard_S1 Web PubSub service and receives the built-in **Web PubSub Service Reader** role at the service scope. This is a read-only data-plane role; use a more privileged role only when the workload must perform operations that require it. The example does not create or configure a workload.

## Run the example

Use Terraform 1.9 or later (below 2.0), and authenticate to the intended Azure subscription. The deploying identity needs permission to create the resource group, managed identity, Web PubSub service, and role assignment, including `Microsoft.Authorization/roleAssignments/write` at the service scope.

From `examples/identity_rbac`:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

The `location` input defaults to `westus3`. `tags` applies to tag-capable resources, and `enable_telemetry` controls module telemetry. `resource_types`, `retry`, `timeouts`, and `ignore_body_changes` expose AzAPI controls. Non-empty ignored-path lists require Terraform 1.11 or later; paths use body-relative dot notation, ignored configuration is not sent to Azure, and setting changes take effect only after apply.

## Use the identity

The outputs include the identity's client and principal IDs. Configure the application workload to use this user-assigned identity and request a token for the Web PubSub service. Attaching the identity to Web PubSub does not grant it to a separate workload automatically. RBAC authorization is separate from network connectivity; configure public or private networking appropriate to the workload.

Remove the example resources when finished:

```powershell
terraform destroy
```
