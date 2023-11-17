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
  resource_prefix = "akc-bas-demo-uks-03"
}

resource "azurerm_resource_group" "akc" {
  name     = "rg-${local.resource_prefix}"
  location = local.location
  tags     = local.tags
}

module "akc" {
  source = "../../"

  name                = "akc-${local.resource_prefix}"
  location            = local.location
  resource_group_name = azurerm_resource_group.akc.name
  tags                = local.tags

  node_count = 2
}
