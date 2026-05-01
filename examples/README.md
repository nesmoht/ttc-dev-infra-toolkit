# Examples

These are fully-worked examples showing what the ttc-dev-infra-toolkit generates.

## webapp

A web application workload with networking, data, and security modules across `dev` and `prd` environments.

**Azure resources created:**

| Resource | dev | prd |
|---|---|---|
| Resource Group | rg-spk-webapp-dev-sdc-001 | rg-spk-webapp-prd-sdc-001 |
| Spoke VNet | vnet-spk-webapp-dev-sdc-001 | vnet-spk-webapp-prd-sdc-001 |
| Subnets | app, shared, private-endpoints | app, shared, private-endpoints |
| NSG (per subnet) | nsg-app-webapp-dev etc. | nsg-app-webapp-prd etc. |
| Storage Account | stwebappdev001 | stwebappprd001 (GRS, no public access) |
| SQL Server | sql-webapp-dev-sdc | sql-webapp-prd-sdc (AAD-only auth) |
| SQL Database | sqldb-webapp-dev (S0, 2 GB) | sqldb-webapp-prd (S2, 50 GB) |
| Key Vault | kv-webapp-dev-sdc | kv-webapp-prd-sdc (no public access) |
| Private Endpoints | — | SQL, Storage, Key Vault |

**Structure:**

```
webapp/
  modules/
    networking/   main.tf  variables.tf  outputs.tf  versions.tf
    data/         main.tf  variables.tf  outputs.tf  versions.tf
    security/     main.tf  variables.tf  outputs.tf  versions.tf
  environments/
    dev/          main.tf  variables.tf  outputs.tf  backend.tf  provider.tf  terraform.tfvars
    prd/          main.tf  variables.tf  outputs.tf  backend.tf  provider.tf  terraform.tfvars
  .claude/
    CLAUDE.md
  AGENTS.md
```

**Try it:**

```bash
cd examples/webapp/environments/dev
# Edit terraform.tfvars with your subscription ID and SQL admin details
tofu init
tofu validate
tofu plan
```
