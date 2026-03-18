# dataplatform — Azure Infrastructure

Workload: dataplatform
Environments: dev, prd
Region: West Europe
Toolkit version: 1.0

## Project Modules
- networking: VNet, subnets, NSG
- data: Storage Account, SQL Server, SQL Database
- security: Key Vault, private endpoints

## Key Resources
- VNet: vnet-dataplatform-{env}-we
- Storage: stdataplatform{env}001
- SQL Server: sql-dataplatform-{env}-we
- SQL Database: sqldb-dataplatform-{env}
- Key Vault: kv-dataplatform-{env}

## State Backend
Resource group: rg-tfstate-shared
Storage account: sttfstateshared001
Container: tfstate
Keys: dataplatform-dev.terraform.tfstate, dataplatform-prd.terraform.tfstate
