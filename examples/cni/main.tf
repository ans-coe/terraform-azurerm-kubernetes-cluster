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
    example = "cni"
    usage   = "demo"
  }
  resource_prefix = "akc-cni-demo-uks-03"
}

resource "azurerm_resource_group" "akc" {
  name     = "rg-${local.resource_prefix}"
  location = local.location
  tags     = local.tags
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
  resource_group_name  = azurerm_resource_group.akc.name
  virtual_network_name = azurerm_virtual_network.akc.name

  address_prefixes = ["10.0.0.0/20"]
}

module "akc" {
  source = "../../"

  name                = "akc-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  node_count = 2

  use_azure_cni  = true
  subnet_id      = azurerm_subnet.akc.id
  network_policy = "azure"
  service_cidr   = "10.1.0.0/16"
}
