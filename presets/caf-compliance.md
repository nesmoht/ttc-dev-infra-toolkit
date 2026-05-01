# Preset: CAF Compliance (Management Groups & Policy Baseline)

Apply this preset when the project needs a CAF-aligned governance foundation:
management group hierarchy, subscription organisation, and security policy baseline.

This is typically a **separate root module** (`terraform/compliance/`) with its own state file,
not mixed into workload modules.

---

## Module structure

```
terraform/compliance/
  provider.tf
  main.tf
  variables.tf
  outputs.tf
  backend.tf
  mgmt-groups/
    main.tf
    variables.tf
    outputs.tf
  policy/
    main.tf
    variables.tf
    outputs.tf
```

---

## CAF Management Group Hierarchy

```
Tenant Root Group
└── Platform
    ├── Connectivity      ← hub network subscription
    ├── Management        ← shared services, logging
    ├── Sandbox           ← no policies applied here
    └── Landing Zones
        ├── NonPrd        ← dev, tst subscriptions
        └── Prd           ← stg, prd subscriptions
```

Policies are assigned to **Landing Zones** and cascade to NonPrd/Prd.
Sandbox is intentionally excluded so teams can experiment freely.

---

## `versions.tf`

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

---

## `mgmt-groups/variables.tf`

```hcl
variable "tenant_root_group_id" {
  description = "ID of the tenant root management group"
  type        = string
}

variable "platform_group_id" {
  description = "Name/ID for the Platform management group"
  type        = string
  default     = "mg-platform"
}

variable "connectivity_group_id" {
  description = "Name/ID for the Connectivity management group"
  type        = string
  default     = "mg-connectivity"
}

variable "management_group_id" {
  description = "Name/ID for the Management management group"
  type        = string
  default     = "mg-management"
}

variable "sandbox_group_id" {
  description = "Name/ID for the Sandbox management group"
  type        = string
  default     = "mg-sandbox"
}

variable "landingzone_group_id" {
  description = "Name/ID for the Landing Zones management group"
  type        = string
  default     = "mg-landingzones"
}

variable "landingzone_nonprd_group_id" {
  description = "Name/ID for the NonPrd landing zone management group"
  type        = string
  default     = "mg-landingzones-nonprd"
}

variable "landingzone_prd_group_id" {
  description = "Name/ID for the Prd landing zone management group"
  type        = string
  default     = "mg-landingzones-prd"
}

variable "dev_subscription" {
  description = "Dev subscription ID to associate with NonPrd landing zone"
  type        = string
  default     = null
}

variable "tst_subscription" {
  description = "Tst subscription ID to associate with NonPrd landing zone"
  type        = string
  default     = null
}

variable "prd_subscription" {
  description = "Prd subscription ID to associate with Prd landing zone"
  type        = string
  default     = null
}
```

---

## `mgmt-groups/main.tf`

```hcl
data "azurerm_client_config" "current" {}

resource "azurerm_management_group" "platform" {
  display_name               = var.platform_group_id
  name                       = var.platform_group_id
  parent_management_group_id = var.tenant_root_group_id
}

resource "azurerm_management_group" "connectivity" {
  display_name               = var.connectivity_group_id
  name                       = var.connectivity_group_id
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "management" {
  display_name               = var.management_group_id
  name                       = var.management_group_id
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "sandbox" {
  display_name               = var.sandbox_group_id
  name                       = var.sandbox_group_id
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landingzone" {
  display_name               = var.landingzone_group_id
  name                       = var.landingzone_group_id
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landingzone_nonprd" {
  display_name               = var.landingzone_nonprd_group_id
  name                       = var.landingzone_nonprd_group_id
  parent_management_group_id = azurerm_management_group.landingzone.id
}

resource "azurerm_management_group" "landingzone_prd" {
  display_name               = var.landingzone_prd_group_id
  name                       = var.landingzone_prd_group_id
  parent_management_group_id = azurerm_management_group.landingzone.id
}

# Subscription associations (only created when subscription IDs are provided)
resource "azurerm_management_group_subscription_association" "dev" {
  count               = var.dev_subscription != null ? 1 : 0
  management_group_id = azurerm_management_group.landingzone_nonprd.id
  subscription_id     = "/subscriptions/${var.dev_subscription}"
}

resource "azurerm_management_group_subscription_association" "tst" {
  count               = var.tst_subscription != null ? 1 : 0
  management_group_id = azurerm_management_group.landingzone_nonprd.id
  subscription_id     = "/subscriptions/${var.tst_subscription}"
}

resource "azurerm_management_group_subscription_association" "prd" {
  count               = var.prd_subscription != null ? 1 : 0
  management_group_id = azurerm_management_group.landingzone_prd.id
  subscription_id     = "/subscriptions/${var.prd_subscription}"
}
```

---

## `mgmt-groups/outputs.tf`

```hcl
output "all" {
  description = "Map of all management group IDs"
  value = {
    platform           = azurerm_management_group.platform.id
    connectivity       = azurerm_management_group.connectivity.id
    management         = azurerm_management_group.management.id
    sandbox            = azurerm_management_group.sandbox.id
    landingzone        = azurerm_management_group.landingzone.id
    landingzone_nonprd = azurerm_management_group.landingzone_nonprd.id
    landingzone_prd    = azurerm_management_group.landingzone_prd.id
  }
}
```

---

## `policy/variables.tf`

```hcl
variable "management_group_id" {
  description = "ID of the management group to assign policies to (typically Landing Zones)"
  type        = string
}

variable "enforce_storage_encryption" {
  description = "Audit customer-managed key encryption for storage accounts"
  type        = bool
  default     = false
}

variable "block_public_ip_creation" {
  description = "Deny creation of public IP addresses"
  type        = bool
  default     = false
}
```

---

## `policy/main.tf`

```hcl
data "azurerm_client_config" "current" {}

#############################################
# 1. ENCRYPTION
#############################################

resource "azurerm_management_group_policy_assignment" "storage_encryption" {
  name                 = "storage-encryption"
  display_name         = "Storage accounts should use customer-managed key for encryption"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6fac406b-40ca-413b-bf8e-0bf964659c25"
  parameters = jsonencode({
    effect = { value = var.enforce_storage_encryption ? "Audit" : "Disabled" }
  })
}

resource "azurerm_management_group_policy_assignment" "storage_tls" {
  name                 = "storage-require-tls12"
  display_name         = "Storage accounts should use minimum TLS version 1.2"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/fe83a0eb-a853-422d-aac2-1bffd182c5d0"
  parameters           = jsonencode({ effect = { value = "Deny" } })
}

resource "azurerm_management_group_policy_assignment" "storage_https" {
  name                 = "storage-require-https"
  display_name         = "Secure transfer to storage accounts should be enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  parameters           = jsonencode({ effect = { value = "Deny" } })
}

resource "azurerm_management_group_policy_assignment" "sql_tde" {
  name                 = "sql-require-tde"
  display_name         = "Transparent Data Encryption on SQL databases should be enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/17k78e20-9358-41c9-923c-fb736d382a12"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "kv_soft_delete" {
  name                 = "kv-require-soft-delete"
  display_name         = "Key vaults should have soft delete enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d"
  parameters           = jsonencode({ effect = { value = "Audit" } })
}

resource "azurerm_management_group_policy_assignment" "kv_purge_protection" {
  name                 = "kv-purge-protection"
  display_name         = "Key vaults should have purge protection enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0b60c0b2-2dc2-4e1c-b5c9-abbed971de53"
  parameters           = jsonencode({ effect = { value = "Audit" } })
}

#############################################
# 2. NETWORK SECURITY
#############################################

resource "azurerm_management_group_policy_assignment" "deny_public_ip" {
  count                = var.block_public_ip_creation ? 1 : 0
  name                 = "deny-public-ip-creation"
  display_name         = "Not allowed resource types - Public IP"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749"
  parameters = jsonencode({
    listOfResourceTypesNotAllowed = { value = ["Microsoft.Network/publicIPAddresses"] }
  })
}

resource "azurerm_management_group_policy_assignment" "sql_no_public_access" {
  name                 = "sql-deny-public-access"
  display_name         = "Azure SQL Database should have the minimal TLS version set to 1.2"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/32e6bbec-16b6-44c2-be37-c5b672d103cf"
  parameters           = jsonencode({ effect = { value = "Audit" } })
}

resource "azurerm_management_group_policy_assignment" "storage_network_rules" {
  name                 = "storage-restrict-network"
  display_name         = "Storage accounts should restrict network access"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c"
  parameters           = jsonencode({ effect = { value = "Audit" } })
}

resource "azurerm_management_group_policy_assignment" "private_endpoint_sql" {
  name                 = "sql-private-endpoint"
  display_name         = "Private endpoint should be enabled for SQL Server"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/7698e800-9299-47a6-b3b6-5a0fee576eed"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "subnet_nsg" {
  name                 = "subnet-require-nsg"
  display_name         = "Subnets should have a Network Security Group"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e71308d3-144b-4262-b144-efdc3cc90517"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "block_rdp_internet" {
  name                 = "block-rdp-from-internet"
  display_name         = "RDP access from the Internet should be blocked"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e372f825-a257-4fb8-9175-797a8a8627d6"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "block_ssh_internet" {
  name                 = "block-ssh-from-internet"
  display_name         = "SSH access from the Internet should be blocked"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2c89a2e5-7285-40fe-afe0-ae8654b92fab"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

#############################################
# 3. IDENTITY & THREAT DETECTION
#############################################

resource "azurerm_management_group_policy_assignment" "vm_managed_identity" {
  name                 = "vm-managed-identity"
  display_name         = "Virtual machines should use managed identities"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/f0e5abd0-2554-4736-b7c0-4ffef23475ef"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "defender_servers" {
  name                 = "enable-defender-servers"
  display_name         = "Microsoft Defender for Servers should be enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8e86a5b6-b9bd-49d1-8e21-4bb8a0862222"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "defender_storage" {
  name                 = "enable-defender-storage"
  display_name         = "Microsoft Defender for Storage should be enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/640d6dca-3c8b-44f4-90e1-6e747b1f6621"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}

resource "azurerm_management_group_policy_assignment" "defender_sql" {
  name                 = "enable-defender-sql"
  display_name         = "Microsoft Defender for SQL should be enabled"
  management_group_id  = var.management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/36d49e87-48c4-4f2e-beed-ba4ed02b71f5"
  parameters           = jsonencode({ effect = { value = "AuditIfNotExists" } })
}
```

---

## Root `main.tf`

```hcl
module "mgmt_groups" {
  source = "./mgmt-groups"

  tenant_root_group_id        = var.tenant_root_group_id
  platform_group_id           = var.platform_group_id
  connectivity_group_id       = var.connectivity_group_id
  management_group_id         = var.management_group_id
  sandbox_group_id            = var.sandbox_group_id
  landingzone_group_id        = var.landingzone_group_id
  landingzone_nonprd_group_id = var.landingzone_nonprd_group_id
  landingzone_prd_group_id    = var.landingzone_prd_group_id
  dev_subscription            = var.dev_subscription
  tst_subscription            = var.tst_subscription
  prd_subscription            = var.prd_subscription
}

# Uncomment to enable policy baseline
# module "policy" {
#   source = "./policy"
#
#   management_group_id        = module.mgmt_groups.all.landingzone
#   enforce_storage_encryption = true
#   block_public_ip_creation   = true
# }
```

---

## Notes

- Management group operations require **Owner** or **Management Group Contributor** at tenant root scope
- Policies are assigned to **Landing Zones** — Sandbox intentionally excluded
- `block_public_ip_creation = true` is a breaking `Deny` — test in NonPrd first
- Policy enforcement mode: use `Audit`/`AuditIfNotExists` before switching to `Deny`
- State backend key: `compliance.tfstate` (separate from `network.tfstate` and `landing-zone.tfstate`)
