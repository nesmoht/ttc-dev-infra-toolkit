# Azure Infrastructure with Terraform

You are an expert in Azure infrastructure and Terraform. Always follow these standards.

## Naming Conventions (Azure CAF)

| Resource | Pattern | Example |
|---|---|---|
| Resource Group | `rg-{workload}-{env}-{region}` | `rg-dataplatform-prd-we` |
| Virtual Network | `vnet-{workload}-{env}-{region}` | `vnet-hub-prd-we` |
| Subnet | `snet-{purpose}-{workload}-{env}` | `snet-data-platform-prd` |
| NSG | `nsg-{snet}-{workload}-{env}` | `nsg-data-platform-prd` |
| Storage Account | `st{workload}{env}{suffix}` | `stdataplatformprd001` (max 24 chars, no hyphens) |
| SQL Server | `sql-{workload}-{env}-{region}` | `sql-dataplatform-prd-we` |
| SQL Database | `sqldb-{workload}-{env}` | `sqldb-analytics-prd` |
| Cosmos DB | `cosmos-{workload}-{env}` | `cosmos-events-prd` |
| Key Vault | `kv-{workload}-{env}` | `kv-dataplatform-prd` |

**Env abbreviations:** `prd`, `dev`, `test`, `stg` — Region: `we` (West Europe), `ne` (North Europe)

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
environments/{env}/
  main.tf        # Module calls
  variables.tf
  outputs.tf
  terraform.tfvars
  backend.tf     # State backend configuration
```

## State Backend (Azure Blob)

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-shared"
    storage_account_name = "sttfstate{suffix}"
    container_name       = "tfstate"
    key                  = "{project}-{env}.terraform.tfstate"
  }
}
```

## Terraform Best Practices

- Always add `description` to all variables and outputs
- Use `validation` blocks on critical variables (env, region)
- Tag all resources with: `environment`, `workload`, `managed-by = "terraform"`
- Use `lifecycle { prevent_destroy = true }` on critical prd resources
- Enable `soft_delete` and `purge_protection` on Key Vaults
- Storage Accounts: `min_tls_version = "TLS1_2"`, `allow_nested_items_to_be_public = false`
- SQL: Enable Azure AD admin, disable SQL authentication in prd
- Use private endpoints for all data services in prd

## Networking Patterns

### Hub-Spoke
- Hub VNet: `10.0.0.0/16` — firewall, DNS, VPN/ExpressRoute
- Spoke VNets: `10.x.0.0/16` — workload-isolated
- Peering: hub ↔ spoke (use `use_remote_gateways` in spokes)

### Standard Subnets in Spoke
| Purpose | CIDR example |
|---|---|
| AzureBastionSubnet | /27 |
| Data layer | /24 |
| App layer | /24 |
| Private Endpoints | /26 |

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
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
