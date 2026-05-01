locals {
  is_prd = var.environment == "prd"

  st_name  = "st${var.workload}${var.environment}${var.storage_instance}"
  sql_name = "sql-${var.workload}-${var.environment}-${var.region_suffix}"
  db_name  = "sqldb-${var.workload}-${var.environment}"

  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)
}

resource "azurerm_storage_account" "this" {
  name                            = local.st_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = local.is_prd ? "GRS" : "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = local.is_prd ? false : true

  blob_properties {
    delete_retention_policy {
      days = local.is_prd ? 30 : 7
    }
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mssql_server" "this" {
  name                          = local.sql_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = local.is_prd ? false : true

  azuread_administrator {
    login_username              = var.sql_aad_admin_login
    object_id                   = var.sql_aad_admin_object_id
    azuread_authentication_only = local.is_prd
  }

  tags = local.common_tags
}

resource "azurerm_mssql_database" "this" {
  name        = local.db_name
  server_id   = azurerm_mssql_server.this.id
  sku_name    = local.is_prd ? "S2" : "S0"
  max_size_gb = local.is_prd ? 50 : 2

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_endpoint" "sql" {
  count = local.is_prd && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-sql-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "sql-${var.workload}-${var.environment}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

resource "azurerm_private_endpoint" "storage" {
  count = local.is_prd && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-st-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "st-${var.workload}-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}
