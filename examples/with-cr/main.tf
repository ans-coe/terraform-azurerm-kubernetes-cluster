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
    example = "with-cr"
    usage   = "demo"
  }
  resource_prefix = "akc-cr-demo-uks-03"
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

  admin_enabled                 = false
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "akc_acrpull" {
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

  node_count = 2
}
