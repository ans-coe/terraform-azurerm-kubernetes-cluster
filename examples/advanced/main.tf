provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  location = "uksouth"
  tags = {
    module  = "kubernetes-cluster"
    example = "advanced"
    usage   = "demo"
  }
  resource_prefix = "akc-adv-demo-uks-03"
}

data "http" "my_ip" {
  url = "https://api.ipify.org"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code from ${self.url} should return 200."
    }
  }
}

resource "azurerm_resource_group" "akc" {
  name     = "rg-${local.resource_prefix}"
  location = local.location
  tags     = local.tags
}

resource "azurerm_container_registry" "akc" {
  name                = lower(replace("cr${local.resource_prefix}", "/[-_]/", ""))
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  sku = "Basic"
}

resource "azurerm_virtual_network" "akc" {
  name                = "vnet-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  address_space = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "akc" {
  name                 = "snet-akc-default"
  resource_group_name  = azurerm_virtual_network.akc.resource_group_name
  virtual_network_name = azurerm_virtual_network.akc.name

  address_prefixes  = ["10.0.0.0/20"]
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

resource "azurerm_user_assigned_identity" "akc" {
  name                = "id-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags
}

resource "azurerm_user_assigned_identity" "akc_nodepool" {
  name                = "id-np-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags
}

resource "azurerm_role_assignment" "akc_nodepool_identity" {
  description                      = "Assign the AKS identity Contributor rights to the Nodepool identity."
  principal_id                     = azurerm_user_assigned_identity.akc.principal_id
  skip_service_principal_aad_check = true

  role_definition_name = "Contributor"
  scope                = azurerm_user_assigned_identity.akc_nodepool.id
}

module "akc" {
  source = "../../"

  name                = "akc-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  authorized_ip_ranges       = ["${data.http.my_ip.response_body}/32"]
  aad_admin_group_object_ids = []

  # cluster_identity and kubelet_identity
  # supports directly passing in identity resource
  cluster_identity = azurerm_user_assigned_identity.akc
  kubelet_identity = azurerm_user_assigned_identity.akc_nodepool

  node_count     = 2
  node_count_max = 3

  use_azure_cni  = true
  subnet_id      = azurerm_subnet.akc.id
  network_policy = "azure"
  service_cidr   = "10.1.0.0/16"

  node_config = {
    os_sku            = "Ubuntu"
    kubelet_disk_type = "OS"
  }

  auto_scaler_profile = {
    balance_similar_node_groups      = true
    expander                         = "least-waste"
    scale_down_utilization_threshold = 0.3
  }

  use_log_analytics               = true
  enable_azure_policy             = true
  enable_http_application_routing = false
  enable_open_service_mesh        = true

  automatic_channel_upgrade = "stable"
  allowed_maintenance_windows = [
    {
      day   = "Saturday"
      hours = [22, 23, 0]
    },
    { day = "Sunday" }
  ]

  # Requires the registry to exist as value can't be determined.
  # Run terraform apply -target azurerm_container_registry.akc first
  registry_ids = [azurerm_container_registry.akc.id]

  depends_on = [azurerm_role_assignment.akc_nodepool_identity]
}
