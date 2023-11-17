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
    module     = "kubernetes-cluster"
    example    = "with-cr"
    usage      = "demo"
    owner      = "demo"
    department = "coe"
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

resource "azurerm_role_assignment" "akc_nodepool_acr_pull" {
  principal_id         = module.akc.nodepool_identity.principal_id
  scope                = azurerm_container_registry.akc.id
  role_definition_name = "AcrPull"

  skip_service_principal_aad_check = true
}

module "akc" {
  source = "../../"

  name                = "akc-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  authorized_ip_ranges = ["${data.http.my_ip.response_body}/32"]
  admin_object_ids     = []

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
}
