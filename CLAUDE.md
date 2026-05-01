# Azure Infrastructure with Terraform

You are an expert in Azure infrastructure and Terraform. Always follow these standards.

## Naming Conventions (Azure CAF)

| Resource | Pattern | Example |
|---|---|---|
| Resource Group | `rg-{workload}-{env}-{region}-{instance}` | `rg-dataplatform-prd-sdc-001` |
| Hub Resource Group | `rg-hub-{shared}-{region}-{instance}` | `rg-hub-shd-sdc-001` |
| Spoke Resource Group | `rg-spk-{workload}-{env}-{region}-{instance}` | `rg-spk-myapp-dev-sdc-001` |
| Virtual Network | `vnet-{workload}-{env}-{region}-{instance}` | `vnet-hub-shd-sdc-001` |
| Spoke VNet | `vnet-spk-{workload}-{env}-{region}-{instance}` | `vnet-spk-myapp-dev-sdc-001` |
| Subnet | `snet-{purpose}-{workload}-{env}-{region}-{instance}` | `snet-app-myapp-dev-sdc-001` |
| NSG | `nsg-{purpose}-{workload}-{env}` | `nsg-app-myapp-dev` |
| Storage Account | `st{workload}{env}{instance}` | `stdataplatformprd001` (max 24 chars, no hyphens) |
| SQL Server | `sql-{workload}-{env}-{region}` | `sql-dataplatform-prd-sdc` |
| SQL Database | `sqldb-{workload}-{env}` | `sqldb-analytics-prd` |
| Cosmos DB | `cosmos-{workload}-{env}` | `cosmos-events-prd` |
| Key Vault | `kv-{workload}-{env}-{region}` | `kv-dataplatform-prd-sdc` |
| VPN Gateway | `vng-hub-{shared}-{region}-{instance}` | `vng-hub-shd-sdc-001` |
| Public IP | `pip-{purpose}-{shared}-{region}-{instance}` | `pip-hub-shd-sdc-001` |
| VNet Peering | `peer-{source}-to-{target}` | `peer-hub-to-dev` |

**Env abbreviations:** `prd`, `dev`, `tst`, `stg` — Region suffix: `sdc` (Sweden Central), `we` (West Europe), `ne` (North Europe) — Instance: `001`, `002`, …

**Azure-reserved subnet names** must be used exactly as-is (no prefix): `GatewaySubnet`, `AzureFirewallSubnet`, `AzureBastionSubnet`, `AppGatewaySubnet`

## Terraform Module Structure

```
modules/{module-name}/
  main.tf        # Resource definitions
  variables.tf   # Input variables with description and validation
  outputs.tf     # Output values
  versions.tf    # Required providers and terraform version
  README.md      # Documentation
```

Root level:
```
terraform/{domain}/          # e.g. network/, compliance/, landing-zone/
  provider.tf    # Provider config (with aliases for multi-subscription)
  main.tf        # Module calls
  variables.tf
  outputs.tf
  terraform.tfvars
  backend.tf     # State backend configuration
  {module}/      # Inline submodules per domain
```

## Locals Naming Pattern

Always derive resource names in a `locals` block — never inline in resource arguments:

```hcl
locals {
  rg_name   = "rg-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"
  vnet_name = "vnet-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"

  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)
}
```

## State Backend (Azure Blob)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-shd"
    storage_account_name = "sttfstateshd001"
    container_name       = "{domain}"
    key                  = "{project}-{env}.terraform.tfstate"
  }
}
```

Use one container per domain (e.g. `network`, `landing-zone`, `compliance`) with separate state keys per environment.

## Terraform Best Practices

- Always add `description` to all variables and outputs
- Use `validation` blocks on critical variables (env, region, sensitive strings)
- Tag all resources with: `environment`, `workload`, `managed-by = "terraform"`
- Use `lifecycle { prevent_destroy = true }` on critical prd resources
- Mark secrets as `sensitive = true` in variable definitions
- Enable `soft_delete_retention_days = 90` and `purge_protection_enabled = true` on Key Vaults
- Storage Accounts: `min_tls_version = "TLS1_2"`, `allow_nested_items_to_be_public = false`
- SQL: Enable Azure AD admin, disable SQL authentication in prd
- Use private endpoints for all data services in prd

## Networking Patterns

### Hub-Spoke
- Hub VNet: shared connectivity subscription, contains VPN gateway, DNS, Bastion
- Spoke VNets: per-environment/workload subscription
- Hub → Spoke peering: `allow_gateway_transit = true`
- Spoke → Hub peering: `use_remote_gateways = true` (routes VPN traffic through hub)
- Use `terraform_data` resource to enforce VPN gateway exists before spoke peering

### Standard Hub Subnets
| Name | CIDR | Notes |
|---|---|---|
| GatewaySubnet | /24 | VPN/ExpressRoute — exact name required |
| AzureFirewallSubnet | /24 | Reserved — exact name required |
| AzureBastionSubnet | /26 | Reserved — exact name required |
| management | /26 | Custom prefix applied |
| sharedservices | /26 | Custom prefix applied |

### Standard Spoke Subnets
| Purpose | CIDR example | Notes |
|---|---|---|
| App / Container | /27 | With delegation if needed |
| Shared services | /27 | With service endpoints |
| Private Endpoints | /26 | |

### Service Endpoints on Spoke Subnets
Add where relevant:
```
Microsoft.AzureCosmosDB
Microsoft.CognitiveServices
Microsoft.Storage
Microsoft.Sql
Microsoft.KeyVault
Microsoft.ContainerRegistry
```

## Key Vault Configuration

```hcl
resource "azurerm_key_vault" "this" {
  name                          = local.kv_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  public_network_access_enabled = false
  enable_rbac_authorization     = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.common_tags
}
```

## OIDC / GitHub Actions Pattern

Use federated credentials (OIDC) for GitHub Actions — never store service principal keys:

```hcl
# Service principal per repo+environment
resource "azuread_application" "this" {
  display_name = "gha-${var.name_prefix}-${var.github_repo}-${var.environment}"
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

resource "azuread_application_federated_identity_credential" "this" {
  application_id = azuread_application.this.id
  display_name   = "${var.github_repo}-${var.environment}"
  subject        = "repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
}

resource "azurerm_role_assignment" "this" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.this.object_id
}
```

GitHub Actions workflow uses: `ARM_USE_OIDC=true`, `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}
```

### Multi-Subscription Providers (Hub-Spoke)

```hcl
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription
  features {}
}

provider "azurerm" {
  alias           = "dev"
  subscription_id = var.dev_subscription
  features {}
}
```
