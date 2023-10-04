###################
# Global Variables
###################

variable "location" {
  description = "The location of created resources."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "The name of the resource group this module will use."
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = null
}

#############
# Monitoring
#############

variable "use_log_analytics" {
  description = "Use Log Analytics for monitoring the deployed resources."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log analytics workspace ID to use if providing an existing workspace."
  type        = string
  default     = null
}

variable "enable_microsoft_defender" {
  description = "Enable Microsoft Defender integration with the cluster."
  type        = bool
  default     = false
}

variable "microsoft_defender_log_analytics_workspace_id" {
  description = "Log analytics workspace ID used with Microsoft Defender."
  type        = string
  default     = null
}

###########
# Security
###########

variable "enable_run_command" {
  description = "Enable Run Command feature with the cluster."
  type        = bool
  default     = false
}

variable "aad_tenant_id" {
  description = "Tenant ID used for AAD RBAC. (defaults to current tenant)"
  type        = string
  default     = null

  validation {
    condition     = var.aad_tenant_id == null || can(regex("\\w{8}-\\w{4}-\\w{4}-\\w{4}-\\w{12}", var.aad_tenant_id))
    error_message = "The aad_tenant_id must to be a valid UUID."
  }
}

variable "enable_oidc_issuer" {
  description = "Enable the OIDC issuer for the cluster."
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity for the cluster."
  type        = bool
  default     = true
}

variable "aad_admin_group_object_ids" {
  description = "Object IDs of AAD Groups that have Admin role over the cluster. These groups will also have read privileges of Azure-level resources."
  type        = list(string)
  default     = []
}

variable "authorized_ip_ranges" {
  description = "CIDRs authorized to communicate with the API Server."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

##########
# Storage
##########

variable "registry_ids" {
  description = "List of registry IDs to give this cluster AcrPull access to."
  type        = list(string)
  default     = []
}

######
# AKS
######

variable "name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use in the cluster."
  type        = string
  default     = null

  validation {
    condition     = var.kubernetes_version == null || can(regex("\\d+\\.\\d+\\.\\d+", var.kubernetes_version))
    error_message = "The kubernetes_version value must be semantic versioning e.g. '1.18.4' if not null."
  }
}

variable "automatic_channel_upgrade" {
  description = "Upgrade channel for the Kubernetes cluster."
  type        = string
  default     = null

  validation {
    condition     = var.automatic_channel_upgrade == null ? true : contains(["patch", "rapid", "node-image", "stable"], var.automatic_channel_upgrade)
    error_message = "The automatic_channel_upgrade must be 'patch', 'rapid', 'node-image' or 'stable'."
  }
}

variable "allowed_maintenance_windows" {
  description = "A list of objects of maintance windows using a day and list of acceptable hours."
  type = list(object({
    day   = string
    hours = optional(list(number), [21])
  }))
  default = []
}

variable "enable_private_cluster" {
  description = "Enable AKS private cluster."
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "The Private DNS Zone ID - can alternatively by System to be AKS-managed or None to bring your own DNS."
  type        = string
  default     = "System"
}

variable "sku_tier" {
  description = "The SKU tier of AKS."
  type        = string
  default     = "Free"
}

variable "cluster_identity" {
  description = "Cluster identity config."
  type = object({
    id           = string
    principal_id = string
  })
  default = null
}

variable "network_policy" {
  description = "Network policy that should be used. ('calico' or 'azure')"
  type        = string
  default     = null

  validation {
    condition     = var.network_policy == null ? true : contains(["calico", "azure"], var.network_policy)
    error_message = "The network_policy must be null, 'calico' or 'azure'."
  }
}

variable "use_azure_cni" {
  description = "Use Azure CNI."
  type        = bool
  default     = false
}

variable "service_cidr" {
  description = "Service CIDR for AKS."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}/\\d{2}", var.service_cidr))
    error_message = "The service_cidr must be a valid CIDR range."
  }
}

variable "node_size" {
  description = "Size of nodes in the default node pool."
  type        = string
  default     = "Standard_B2ms"
}

variable "node_count" {
  description = "Default number of nodes in the default node pool or minimum number of nodes."
  type        = number
  default     = 2
}

variable "node_count_max" {
  description = "Maximum number of nodes in the AKS cluster."
  type        = number
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to use with the default nodepool if using Azure CNI."
  type        = string
  default     = null
}

variable "pod_subnet_id" {
  description = "Subnet ID to use with default nodepool pods for Azure CNI."
  type        = string
  default     = null
}

variable "node_critical_addons_only" {
  description = "Taint the default node pool with 'CriticalAddonsOnly=true:NoSchedule'."
  type        = bool
  default     = false
}

variable "node_config" {
  description = "Additional default node pool configuration not covered by base variables."
  type = object({
    pool_name = optional(string, "system")
    tags      = optional(map(string))

    zones                    = optional(list(number), [1, 2, 3])
    enable_node_public_ip    = optional(bool, false)
    node_public_ip_prefix_id = optional(string)

    os_sku                 = optional(string)
    os_disk_size_gb        = optional(string)
    os_disk_type           = optional(number)
    ultra_ssd_enabled      = optional(bool)
    kubelet_disk_type      = optional(string)
    enable_host_encryption = optional(bool)
    fips_enabled           = optional(bool)

    orchestrator_version = optional(string)
    max_pods             = optional(number, 50)
    node_labels          = optional(map(string))
  })
  default = {}
}

variable "auto_scaler_profile" {
  description = "Autoscaler config."
  type = object({
    scan_interval                 = optional(string)
    skip_nodes_with_local_storage = optional(bool)
    skip_nodes_with_system_pods   = optional(bool)
    empty_bulk_delete_max         = optional(string)
    balance_similar_node_groups   = optional(bool)
    new_pod_scale_up_delay        = optional(string)

    max_graceful_termination_sec = optional(string)
    max_node_provisioning_time   = optional(string)
    max_unready_nodes            = optional(number)
    max_unready_percentage       = optional(number)

    scale_down_unready               = optional(string)
    scale_down_unneeded              = optional(string)
    scale_down_utilization_threshold = optional(string)
    scale_down_delay_after_add       = optional(string)
    scale_down_delay_after_delete    = optional(string)
    scale_down_delay_after_failure   = optional(string)
  })
  default = {}
}

variable "kubelet_identity" {
  description = "Kubelet identity config."
  type = object({
    id           = string
    principal_id = string
    client_id    = string
  })
  default = null
}

variable "enable_azure_policy" {
  description = "Enable the Azure Policy plugin."
  type        = bool
  default     = false
}

variable "enable_http_application_routing" {
  description = "Enable the HTTP Application Routing plugin."
  type        = bool
  default     = false
}

variable "enable_open_service_mesh" {
  description = "Enable the Open Service Mesh plugin."
  type        = bool
  default     = false
}

variable "enable_ingress_application_gateway" {
  description = "Enable the ingress application gateway plugin."
  type        = bool
  default     = false
}

variable "ingress_application_gateway_id" {
  description = "The ID of an existing Application Gateway to integrate with AKS."
  type        = string
  default     = null
}

variable "ingress_application_gateway_name" {
  description = "The name of an Application Gateway to integrate with AKS or create in the Nodepool resource group."
  type        = string
  default     = null
}

variable "ingress_application_subnet_id" {
  description = "The ID of the Subnet the Application Gateway will be created on."
  type        = string
  default     = null
}

variable "ingress_application_subnet_cidr" {
  description = "The CIDR used when creating an Application Gateway."
  type        = string
  default     = null
}

variable "enable_blob_driver" {
  description = "Enable blob_driver feature on the storage profile of the cluster."
  type        = bool
  default     = null
}

variable "enable_disk_driver" {
  description = "Enable disk_driver feature on the storage profile of the cluster."
  type        = bool
  default     = null
}

variable "disk_driver_version" {
  description = "Version of the disk_driver feature on the storage profile of the cluster."
  type        = bool
  default     = null
}

variable "enable_file_driver" {
  description = "Enable file_driver feature on the storage profile of the cluster."
  type        = bool
  default     = null
}

variable "enable_azure_keyvault_secrets_provider" {
  description = "Enable the Azure Keyvault secrets provider plugin."
  type        = bool
  default     = false
}

variable "azure_keyvault_secrets_provider_config" {
  description = "Object containing configuration for the Azure Keyvault secrets provider plugin."
  type = object({
    enable_secret_rotation = optional(bool, true)
    rotation_interval      = optional(string, "2m")
  })
  default = {
    enable_secret_rotation = true
  }
}

variable "enable_flux" {
  description = "Enable the flux extension on the cluster."
  type        = bool
  default     = false
}
