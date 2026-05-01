# webapp — Azure Infrastructure

Workload: webapp
Environments: dev, prd
Region: Sweden Central (sdc)
Toolkit version: 1.0

## Project Modules

- **networking** — Spoke VNet, subnets (app, shared, private-endpoints), NSG per subnet
- **data** — Storage Account, SQL Server + Database, private endpoints (prd only)
- **security** — Key Vault with RBAC, private endpoint (prd only)

## Key Resources

| Resource | dev | prd |
|---|---|---|
| Resource Group | rg-spk-webapp-dev-sdc-001 | rg-spk-webapp-prd-sdc-001 |
| VNet | vnet-spk-webapp-dev-sdc-001 | vnet-spk-webapp-prd-sdc-001 |
| Storage Account | stwebappdev001 | stwebappprd001 |
| SQL Server | sql-webapp-dev-sdc | sql-webapp-prd-sdc |
| Key Vault | kv-webapp-dev-sdc | kv-webapp-prd-sdc |

## State Backend

Resource group: rg-tfstate-shd
Storage account: sttfstateshd001
Container: landing-zone
Keys: webapp-dev.terraform.tfstate / webapp-prd.terraform.tfstate

## Notes

- Private endpoints enabled for SQL and Storage in prd only
- SQL auth-only mode (no password) in prd
- Key Vault public access disabled in prd
