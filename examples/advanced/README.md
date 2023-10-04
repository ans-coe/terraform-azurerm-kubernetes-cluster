# Example - Advanced

This example includes all variables to display as features of the module as possible, including the usage of outside modules to interact with AKS.

> NOTE: You may experience issues after first plan with the `helm_release.ingress_nginx` resource. This works on Apply fine but subsequent applies fail and it's probably best not to do it. Either way you have a nice example of using some extra config in [kube.tf](./kube.tf). Read [here](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#stacking-with-managed-kubernetes-cluster-resources) for more info.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Inputs

No inputs.

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_resource_group.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.akc_nodepool_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.akc_nodepool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [http_http.my_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_akc"></a> [akc](#module\_akc) | ../../ | n/a |
<!-- END_TF_DOCS -->
