locals {
  is_prd  = var.environment == "prd"
  kv_name = "kv-${var.workload}-${var.environment}-${var.region_suffix}"

  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = local.is_prd ? false : true
  enable_rbac_authorization     = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_endpoint" "kv" {
  count = local.is_prd && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-kv-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "kv-${var.workload}-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
