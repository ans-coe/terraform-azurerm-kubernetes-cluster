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
    example = "private"
    usage   = "demo"
  }
  resource_prefix = "akc-pri-demo-uks-03"
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
  resource_group_name  = azurerm_virtual_network.akc.resource_group_name
  virtual_network_name = azurerm_virtual_network.akc.name

  address_prefixes  = ["10.0.0.0/20"]
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

resource "azurerm_private_dns_zone" "akc" {
  name                = "privatelink.${local.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.akc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "akc" {
  name                  = azurerm_virtual_network.akc.name
  resource_group_name   = azurerm_resource_group.akc.name
  private_dns_zone_name = azurerm_private_dns_zone.akc.name
  virtual_network_id    = azurerm_virtual_network.akc.id
}

data "azurerm_subscription" "current" {}

module "akc" {
  source = "../../"

  name                = "akc-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  enable_private_cluster = true
  // NOTE: Internally, this relies on a 'count' for assigning the role.
  //       This is a workaround for getting the module to work properly with bring your own DNS.
  private_dns_zone_id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/privateDnsZones/privatelink.%s.azmk8s.io",
    data.azurerm_subscription.current.subscription_id, "rg-${local.resource_prefix}", local.location
  )

  use_azure_cni  = true
  subnet_id      = azurerm_subnet.akc.id
  network_policy = "azure"

  // NOTE: Add an explicit dependenccy to the private DNS zone.
  depends_on = [ azurerm_private_dns_zone.akc ]
}
