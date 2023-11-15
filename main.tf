###########
# Identity
###########

resource "azurerm_user_assigned_identity" "cluster" {
  name                = var.cluster_identity_name == null ? "id-${var.name}" : var.cluster_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "nodepool" {
  name                = var.nodepool_identity_name == null ? "id-nodepool-${var.name}" : var.nodepool_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "main_aks_user_identity_kubelet_identity_contributor" {
  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  scope                = azurerm_user_assigned_identity.nodepool.id
  role_definition_name = "Managed Identity Operator"

  skip_service_principal_aad_check = true
}

##########
# Cluster
##########

locals {
  use_public_dns_prefix = anytrue([
    (var.enable_private_cluster && var.private_dns_zone_id == "System"),
    (!var.enable_private_cluster),
  ])
  use_private_dns_prefix = anytrue([
    (var.enable_private_cluster && var.private_dns_zone_id != "System")
  ])
}

// NOTE: scope has been set up to ensure name-based errors don't occur, as the resource
//       checks the schema of the name

resource "azurerm_role_assignment" "main_aks_user_identity_network_contributor" {
  count = var.use_azure_cni ? 1 : 0

  principal_id = azurerm_user_assigned_identity.cluster.principal_id
  // NOTE: converts the subnet_id to the vnet_id to set role at a higher level
  scope                = try(one(regex("(/.*)/subnets", var.subnet_id)), "/subscriptions/UNUSED")
  role_definition_name = "Network Contributor"

  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "main_aks_user_identity_private_dns_zone_contributor" {
  count = var.enable_private_cluster && var.private_dns_zone_id != "System" ? 1 : 0

  principal_id         = azurerm_user_assigned_identity.cluster.principal_id
  scope                = coalesce(var.private_dns_zone_id, "/subscriptions/UNUSED")
  role_definition_name = "Private DNS Zone Contributor"

  skip_service_principal_aad_check = true
}

// NOTE: ignore tfsec rule relating to configuring monitoring and RBAC rule as it is implicitly enabled on this version.
#tfsec:ignore:azure-container-logging tfsec:ignore:azure-container-use-rbac-permissions tfsec:ignore:azure-container-limit-authorized-ips
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dns_prefix                = local.use_public_dns_prefix ? var.name : null
  kubernetes_version        = var.kubernetes_version == null ? data.azurerm_kubernetes_service_versions.current.latest_version : var.kubernetes_version
  automatic_channel_upgrade = var.automatic_channel_upgrade
  sku_tier                  = var.sku_tier

  private_cluster_enabled    = var.enable_private_cluster
  dns_prefix_private_cluster = local.use_private_dns_prefix ? var.name : null
  private_dns_zone_id        = local.use_private_dns_prefix ? var.private_dns_zone_id : null

  api_server_access_profile {
    authorized_ip_ranges = var.enable_private_cluster ? null : var.authorized_ip_ranges
  }
  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = var.admin_object_ids
    azure_rbac_enabled     = true
  }
  run_command_enabled    = var.enable_run_command
  local_account_disabled = true

  network_profile {
    network_plugin    = var.use_azure_cni ? "azure" : "kubenet"
    network_policy    = var.network_policy
    load_balancer_sku = "standard"

    pod_cidr       = var.use_azure_cni ? null : "10.244.0.0/16"
    service_cidr   = var.service_cidr
    dns_service_ip = cidrhost(var.service_cidr, 10)
  }

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.nodepool.id
    object_id                 = azurerm_user_assigned_identity.nodepool.principal_id
    client_id                 = azurerm_user_assigned_identity.nodepool.client_id
  }

  default_node_pool {
    name                        = lower(replace(var.node_config["pool_name"], "/[_-]/", ""))
    temporary_name_for_rotation = "systmp"
    type                        = "VirtualMachineScaleSets"
    tags                        = merge(var.tags, var.node_config["tags"])

    vm_size             = var.node_size
    node_count          = var.node_count
    enable_auto_scaling = var.node_count_max != null ? true : false
    min_count           = var.node_count_max != null ? var.node_count : null
    max_count           = var.node_count_max

    zones                    = var.node_config["zones"]
    vnet_subnet_id           = var.use_azure_cni ? var.subnet_id : null
    enable_node_public_ip    = var.node_config["enable_node_public_ip"]
    node_public_ip_prefix_id = var.node_config["node_public_ip_prefix_id"]

    os_sku                 = var.node_config["os_sku"]
    os_disk_size_gb        = var.node_config["os_disk_size_gb"]
    os_disk_type           = var.node_config["os_disk_type"]
    ultra_ssd_enabled      = var.node_config["ultra_ssd_enabled"]
    kubelet_disk_type      = var.node_config["kubelet_disk_type"]
    enable_host_encryption = var.node_config["enable_host_encryption"]
    fips_enabled           = var.node_config["fips_enabled"]

    orchestrator_version         = var.node_config["orchestrator_version"]
    max_pods                     = var.node_config["max_pods"]
    only_critical_addons_enabled = var.node_config["critical_addons_only"]
    node_labels                  = var.node_config["node_labels"]

    upgrade_settings {
      max_surge = "10%"
    }
  }

  auto_scaler_profile {
    scan_interval                 = var.auto_scaler_profile["scan_interval"]
    skip_nodes_with_local_storage = var.auto_scaler_profile["skip_nodes_with_local_storage"]
    skip_nodes_with_system_pods   = var.auto_scaler_profile["skip_nodes_with_system_pods"]
    empty_bulk_delete_max         = var.auto_scaler_profile["empty_bulk_delete_max"]
    balance_similar_node_groups   = var.auto_scaler_profile["balance_similar_node_groups"]
    new_pod_scale_up_delay        = var.auto_scaler_profile["new_pod_scale_up_delay"]

    max_graceful_termination_sec = var.auto_scaler_profile["max_graceful_termination_sec"]
    max_node_provisioning_time   = var.auto_scaler_profile["max_node_provisioning_time"]
    max_unready_nodes            = var.auto_scaler_profile["max_unready_nodes"]
    max_unready_percentage       = var.auto_scaler_profile["max_unready_percentage"]

    scale_down_unready               = var.auto_scaler_profile["scale_down_unready"]
    scale_down_unneeded              = var.auto_scaler_profile["scale_down_unneeded"]
    scale_down_utilization_threshold = var.auto_scaler_profile["scale_down_utilization_threshold"]
    scale_down_delay_after_add       = var.auto_scaler_profile["scale_down_delay_after_add"]
    scale_down_delay_after_delete    = var.auto_scaler_profile["scale_down_delay_after_delete"]
    scale_down_delay_after_failure   = var.auto_scaler_profile["scale_down_delay_after_failure"]
  }

  oidc_issuer_enabled              = var.enable_oidc_issuer
  workload_identity_enabled        = var.enable_workload_identity
  azure_policy_enabled             = var.enable_azure_policy
  http_application_routing_enabled = var.enable_http_application_routing
  open_service_mesh_enabled        = var.enable_open_service_mesh

  dynamic "oms_agent" {
    for_each = var.log_analytics["enabled"] ? [1] : []
    content {
      log_analytics_workspace_id      = var.log_analytics["workspace_id"]
      msi_auth_for_monitoring_enabled = var.log_analytics["enable_msi_auth"]
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender["enabled"] ? [1] : []
    content {
      log_analytics_workspace_id = var.microsoft_defender["workspace_id"]
    }
  }

  storage_profile {
    blob_driver_enabled         = var.storage_profile["blob_driver_enabled"]
    file_driver_enabled         = var.storage_profile["file_driver_enabled"]
    disk_driver_enabled         = var.storage_profile["disk_driver_enabled"]
    disk_driver_version         = var.storage_profile["disk_driver_version"]
    snapshot_controller_enabled = var.storage_profile["snapshot_controller_enabled"]
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider["enabled"] ? [1] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider["enable_secret_rotation"]
      secret_rotation_interval = var.key_vault_secrets_provider["rotation_interval"]
    }
  }

  dynamic "maintenance_window" {
    for_each = length(var.allowed_maintenance_windows) > 0 ? [1] : []
    content {
      dynamic "allowed" {
        for_each = var.allowed_maintenance_windows
        content {
          day   = allowed.value["day"]
          hours = allowed.value["hours"]
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster.id]
  }

  depends_on = [
    // NOTE: Required as this functions with the user identity.
    azurerm_role_assignment.main_aks_user_identity_network_contributor,
    azurerm_role_assignment.main_aks_user_identity_private_dns_zone_contributor,
    azurerm_role_assignment.main_aks_user_identity_kubelet_identity_contributor,
  ]

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      kubernetes_version
    ]
  }
}

resource "azurerm_kubernetes_cluster_extension" "main_flux" {
  count = var.enable_flux ? 1 : 0

  name           = "flux"
  cluster_id     = azurerm_kubernetes_cluster.main.id
  extension_type = "microsoft.flux"

  release_namespace = "flux-system"
  release_train     = "Stable"
}

##############################
# Additional role assignments
##############################

resource "azurerm_role_assignment" "main_aks_cluster_admin" {
  for_each = var.admin_object_ids

  principal_id         = each.value
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"

  skip_service_principal_aad_check = false
}
