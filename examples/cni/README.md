# Example - CNI

This example extends on the [basic](../basic/README.md) template by also setting up Azure CNI.

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
| [azurerm_resource_group.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.akc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_akc"></a> [akc](#module\_akc) | ../../ | n/a |
<!-- END_TF_DOCS -->
