# Example - With ACR

This example extends on the [basic](../basic/README.md) template by adding the pre-defined Container Registry resource.

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
| [azurerm_role_assignment.akc_acrpull](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_akc"></a> [akc](#module\_akc) | ../../ | n/a |
<!-- END_TF_DOCS -->
