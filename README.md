# Terraform (Module) - AzureRM - Kubernetes Cluster

#### Table of Contents

1. [Usage](#usage)
2. [Requirements](#requirements)
3. [Inputs](#inputs)
4. [Outputs](#outputs)
5. [Resources](#resources)
6. [Modules](#modules)

## Usage

This module is used to manage an Azure Kubernetes Cluster with numerous options including support for Azure monitoring and an attached, simple, dedicated ACR (Azure Container Registry). This module is solely focused on the AzureRM configuration and does not work with AzureAD elements such as groups.

Examples can be found under the [examples](./examples/) directory.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the AKS cluster. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group this module will use. | `string` | n/a | yes |
| <a name="input_admin_object_ids"></a> [admin\_object\_ids](#input\_admin\_object\_ids) | Object IDs of AAD Groups that have Admin role over the cluster. These groups will also have read privileges of Azure-level resources. | `set(string)` | `[]` | no |
| <a name="input_allowed_maintenance_windows"></a> [allowed\_maintenance\_windows](#input\_allowed\_maintenance\_windows) | A list of objects of maintance windows using a day and list of acceptable hours. | <pre>list(object({<br>    day   = string<br>    hours = optional(list(number), [21])<br>  }))</pre> | `[]` | no |
| <a name="input_authorized_ip_ranges"></a> [authorized\_ip\_ranges](#input\_authorized\_ip\_ranges) | CIDRs authorized to communicate with the API Server. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_auto_scaler_profile"></a> [auto\_scaler\_profile](#input\_auto\_scaler\_profile) | Autoscaler config. | <pre>object({<br>    scan_interval                 = optional(string)<br>    skip_nodes_with_local_storage = optional(bool)<br>    skip_nodes_with_system_pods   = optional(bool)<br>    empty_bulk_delete_max         = optional(string)<br>    balance_similar_node_groups   = optional(bool)<br>    new_pod_scale_up_delay        = optional(string)<br><br>    max_graceful_termination_sec = optional(string)<br>    max_node_provisioning_time   = optional(string)<br>    max_unready_nodes            = optional(number)<br>    max_unready_percentage       = optional(number)<br><br>    scale_down_unready               = optional(string)<br>    scale_down_unneeded              = optional(string)<br>    scale_down_utilization_threshold = optional(string)<br>    scale_down_delay_after_add       = optional(string)<br>    scale_down_delay_after_delete    = optional(string)<br>    scale_down_delay_after_failure   = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_automatic_channel_upgrade"></a> [automatic\_channel\_upgrade](#input\_automatic\_channel\_upgrade) | Upgrade channel for the Kubernetes cluster. | `string` | `null` | no |
| <a name="input_cluster_identity_name"></a> [cluster\_identity\_name](#input\_cluster\_identity\_name) | Name of the user assigned cluster identity. | `string` | `null` | no |
| <a name="input_enable_azure_policy"></a> [enable\_azure\_policy](#input\_enable\_azure\_policy) | Enable the Azure Policy plugin. | `bool` | `false` | no |
| <a name="input_enable_flux"></a> [enable\_flux](#input\_enable\_flux) | Enable the flux extension on the cluster. | `bool` | `false` | no |
| <a name="input_enable_http_application_routing"></a> [enable\_http\_application\_routing](#input\_enable\_http\_application\_routing) | Enable the HTTP Application Routing plugin. | `bool` | `false` | no |
| <a name="input_enable_oidc_issuer"></a> [enable\_oidc\_issuer](#input\_enable\_oidc\_issuer) | Enable the OIDC issuer for the cluster. | `bool` | `true` | no |
| <a name="input_enable_open_service_mesh"></a> [enable\_open\_service\_mesh](#input\_enable\_open\_service\_mesh) | Enable the Open Service Mesh plugin. | `bool` | `false` | no |
| <a name="input_enable_private_cluster"></a> [enable\_private\_cluster](#input\_enable\_private\_cluster) | Enable AKS private cluster. | `bool` | `false` | no |
| <a name="input_enable_run_command"></a> [enable\_run\_command](#input\_enable\_run\_command) | Enable Run Command feature with the cluster. | `bool` | `false` | no |
| <a name="input_enable_workload_identity"></a> [enable\_workload\_identity](#input\_enable\_workload\_identity) | Enable workload identity for the cluster. | `bool` | `true` | no |
| <a name="input_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#input\_key\_vault\_secrets\_provider) | Configuration for the key vault secrets provider plugin. | <pre>object({<br>    enabled                = optional(bool, false)<br>    enable_secret_rotation = optional(bool, true)<br>    rotation_interval      = optional(string, "2m")<br>  })</pre> | `{}` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Version of Kubernetes to use in the cluster. | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location of created resources. | `string` | `"uksouth"` | no |
| <a name="input_log_analytics"></a> [log\_analytics](#input\_log\_analytics) | Configuration for the OMS Agent plugin. | <pre>object({<br>    enabled         = optional(bool, false)<br>    enable_msi_auth = optional(bool, true)<br>    workspace_id    = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_microsoft_defender"></a> [microsoft\_defender](#input\_microsoft\_defender) | Configuration for the Microsoft Defender plugin. | <pre>object({<br>    enabled      = optional(bool, false)<br>    workspace_id = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_network_policy"></a> [network\_policy](#input\_network\_policy) | Network policy that should be used. ('calico' or 'azure') | `string` | `null` | no |
| <a name="input_node_config"></a> [node\_config](#input\_node\_config) | Additional default node pool configuration not covered by base variables. | <pre>object({<br>    pool_name = optional(string, "system")<br>    tags      = optional(map(string))<br><br>    zones                    = optional(set(number))<br>    enable_node_public_ip    = optional(bool, false)<br>    node_public_ip_prefix_id = optional(string)<br><br>    os_sku                 = optional(string)<br>    os_disk_size_gb        = optional(string)<br>    os_disk_type           = optional(number)<br>    ultra_ssd_enabled      = optional(bool)<br>    kubelet_disk_type      = optional(string)<br>    enable_host_encryption = optional(bool)<br>    fips_enabled           = optional(bool)<br><br>    orchestrator_version = optional(string)<br>    critical_addons_only = optional(bool, false)<br>    max_pods             = optional(number, 50)<br>    node_labels          = optional(map(string))<br>  })</pre> | `{}` | no |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Default number of nodes in the default node pool or minimum number of nodes. | `number` | `2` | no |
| <a name="input_node_count_max"></a> [node\_count\_max](#input\_node\_count\_max) | Maximum number of nodes in the AKS cluster. | `number` | `null` | no |
| <a name="input_node_size"></a> [node\_size](#input\_node\_size) | Size of nodes in the default node pool. | `string` | `"Standard_D2s_v3"` | no |
| <a name="input_nodepool_identity_name"></a> [nodepool\_identity\_name](#input\_nodepool\_identity\_name) | Name of the user assigned kubelet identity. | `string` | `null` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | The Private DNS Zone ID - can alternatively by System to be AKS-managed or None to bring your own DNS. | `string` | `"System"` | no |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | Service CIDR for AKS. | `string` | `"10.250.0.0/20"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | The SKU tier of AKS. | `string` | `"Free"` | no |
| <a name="input_storage_profile"></a> [storage\_profile](#input\_storage\_profile) | Storage profile of the cluster. | <pre>object({<br>    blob_driver_enabled         = optional(bool)<br>    file_driver_enabled         = optional(bool)<br>    disk_driver_enabled         = optional(bool)<br>    disk_driver_version         = optional(string)<br>    snapshot_controller_enabled = optional(bool)<br>  })</pre> | `{}` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID to use with the default nodepool if using Azure CNI. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to created resources. | `map(string)` | `null` | no |
| <a name="input_use_azure_cni"></a> [use\_azure\_cni](#input\_use\_azure\_cni) | Use Azure CNI. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | Resource ID of the Azure Kubernetes cluster. |
| <a name="output_identity"></a> [identity](#output\_identity) | Azure Kubernetes cluster identity. |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | Azure Kubernetes cluster configuration. |
| <a name="output_location"></a> [location](#output\_location) | Location of the Azure Kubernetes cluster. |
| <a name="output_name"></a> [name](#output\_name) | Name of the Azure Kubernetes cluster. |
| <a name="output_node_resource_group_name"></a> [node\_resource\_group\_name](#output\_node\_resource\_group\_name) | Name of the Azure Kubernetes cluster resource group. |
| <a name="output_nodepool_identity"></a> [nodepool\_identity](#output\_nodepool\_identity) | Azure Kubernetes cluster kubelet identity. |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | The OIDC Issuer url of the cluster. |

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_extension.main_flux](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_extension) | resource |
| [azurerm_role_assignment.main_aks_cluster_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.main_aks_user_identity_kubelet_identity_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.main_aks_user_identity_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.main_aks_user_identity_private_dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_user_assigned_identity.nodepool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_kubernetes_service_versions.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_service_versions) | data source |

## Modules

No modules.
<!-- END_TF_DOCS -->
