locals {
  workload     = "webapp"
  environment  = "dev"
  location     = "swedencentral"
  region_suffix = "sdc"
  instance     = "001"

  rg_name = "rg-spk-${local.workload}-${local.environment}-${local.region_suffix}-${local.instance}"

  common_tags = {
    environment = local.environment
    workload    = local.workload
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = local.location
  tags     = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  workload            = local.workload
  environment         = local.environment
  location            = local.location
  region_suffix       = local.region_suffix
  instance            = local.instance
  resource_group_name = azurerm_resource_group.this.name
  address_space       = "10.10.0.0/16"

  subnets = {
    app = {
      cidr = "10.10.1.0/27"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql",
      ]
    }
    shared = {
      cidr = "10.10.1.32/27"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
      ]
    }
    private-endpoints = {
      cidr = "10.10.2.0/26"
    }
  }

  tags = local.common_tags
}

module "data" {
  source = "../../modules/data"

  workload            = local.workload
  environment         = local.environment
  location            = local.location
  region_suffix       = local.region_suffix
  resource_group_name = azurerm_resource_group.this.name
  storage_instance    = local.instance

  sql_aad_admin_login     = var.sql_aad_admin_login
  sql_aad_admin_object_id = var.sql_aad_admin_object_id

  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"

  workload            = local.workload
  environment         = local.environment
  location            = local.location
  region_suffix       = local.region_suffix
  resource_group_name = azurerm_resource_group.this.name

  tags = local.common_tags
}
