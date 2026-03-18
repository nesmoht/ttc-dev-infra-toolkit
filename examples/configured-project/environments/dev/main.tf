resource "azurerm_resource_group" "this" {
  name     = "rg-dataplatform-dev-we"
  location = var.location
  tags     = local.common_tags
}

locals {
  common_tags = {
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }
}

module "networking" {
  source = "../../modules/networking"

  workload            = var.workload
  environment         = var.environment
  location            = var.location
  location_short      = "we"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = "10.1.0.0/16"
  tags                = local.common_tags
}

module "data" {
  source = "../../modules/data"

  workload               = var.workload
  environment            = var.environment
  location               = var.location
  location_short         = "we"
  resource_group_name    = azurerm_resource_group.this.name
  storage_account_suffix = "001"
  enable_sql             = true
  enable_cosmos          = false
  tags                   = local.common_tags
}

module "security" {
  source = "../../modules/security"

  workload            = var.workload
  environment         = var.environment
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}
