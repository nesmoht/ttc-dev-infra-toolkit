# Preset: Data Platform

Apply this preset when the project needs Storage Account, SQL Server/Database, Cosmos DB, or Key Vault.

## Module: `modules/data/`

### `versions.tf`
```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

### `variables.tf`
```hcl
variable "workload" {
  description = "Workload name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "test", "stg", "prd"], var.environment)
    error_message = "Environment must be one of: dev, test, stg, prd"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "location_short" {
  description = "Short region code used in naming"
  type        = string
  default     = "we"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "storage_account_suffix" {
  description = "Unique suffix for storage account name (max 5 chars, lowercase)"
  type        = string
}

variable "enable_sql" {
  description = "Whether to create SQL Server and Database"
  type        = bool
  default     = true
}

variable "enable_cosmos" {
  description = "Whether to create a Cosmos DB account"
  type        = bool
  default     = false
}

variable "sql_aad_admin_login" {
  description = "Azure AD admin login name for SQL Server"
  type        = string
  default     = null
}

variable "sql_aad_admin_object_id" {
  description = "Azure AD object ID of the SQL admin user or group"
  type        = string
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints (required in prd)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
```

### `main.tf`
```hcl
locals {
  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)

  is_prd = var.environment == "prd"
}

# Storage Account
resource "azurerm_storage_account" "this" {
  name                            = "st${var.workload}${var.environment}${var.storage_account_suffix}"
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

# SQL Server (optional)
resource "azurerm_mssql_server" "this" {
  count = var.enable_sql ? 1 : 0

  name                          = "sql-${var.workload}-${var.environment}-${var.location_short}"
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
  count = var.enable_sql ? 1 : 0

  name        = "sqldb-${var.workload}-${var.environment}"
  server_id   = azurerm_mssql_server.this[0].id
  sku_name    = local.is_prd ? "S2" : "S0"
  max_size_gb = local.is_prd ? 50 : 2

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

# Cosmos DB (optional)
resource "azurerm_cosmosdb_account" "this" {
  count = var.enable_cosmos ? 1 : 0

  name                = "cosmos-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  public_network_access_enabled = local.is_prd ? false : true
  tags                          = local.common_tags
}
```

### `outputs.tf`
```hcl
output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "sql_server_id" {
  description = "Resource ID of the SQL server"
  value       = var.enable_sql ? azurerm_mssql_server.this[0].id : null
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = var.enable_sql ? azurerm_mssql_server.this[0].fully_qualified_domain_name : null
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint URI"
  value       = var.enable_cosmos ? azurerm_cosmosdb_account.this[0].endpoint : null
}
```

## Module: `modules/security/`

### `main.tf`
```hcl
locals {
  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                        = "kv-${var.workload}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  public_network_access_enabled = var.environment == "prd" ? false : true
  enable_rbac_authorization   = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}
```
