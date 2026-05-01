# Preset: Networking (Hub-Spoke)

Apply this preset when the project needs VNet, subnets, NSG, and/or hub-spoke peering.

## Module: `modules/networking/`

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
    condition     = contains(["dev", "tst", "stg", "prd"], var.environment)
    error_message = "Environment must be one of: dev, tst, stg, prd"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "swedencentral"
}

variable "region_suffix" {
  description = "Short region code used in naming (e.g. sdc, we, ne)"
  type        = string
  default     = "sdc"
}

variable "instance" {
  description = "Instance number for resource naming (e.g. 001)"
  type        = string
  default     = "001"
}

variable "address_space" {
  description = "VNet address space CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnets" {
  description = "Map of subnet key to object with cidr and optional service_endpoints and delegation"
  type = map(object({
    cidr               = string
    service_endpoints  = optional(list(string), [])
    delegation_name    = optional(string, null)
    delegation_action  = optional(string, null)
  }))
  default = {
    app = {
      cidr = "10.1.1.0/27"
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql"
      ]
    }
    shared = {
      cidr = "10.1.1.32/27"
      service_endpoints = [
        "Microsoft.AzureCosmosDB",
        "Microsoft.Storage",
        "Microsoft.KeyVault"
      ]
    }
    private-endpoints = {
      cidr = "10.1.2.0/26"
    }
  }
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for peering (optional)"
  type        = string
  default     = null
}

variable "use_remote_gateways" {
  description = "Route traffic through hub VPN gateway. Set to true when hub has a VPN or ExpressRoute gateway."
  type        = bool
  default     = false
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
  # Azure-reserved subnet names must not be prefixed
  azure_reserved_subnets = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "AzureBastionSubnet",
    "AppGatewaySubnet",
  ]

  vnet_name = "vnet-spk-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"
  rg_name   = var.resource_group_name

  subnet_names = {
    for k, v in var.subnets : k => contains(local.azure_reserved_subnets, k) ? k : "snet-${k}-spk-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"
  }

  common_tags = merge({
    environment = var.environment
    workload    = var.workload
    managed-by  = "terraform"
  }, var.tags)
}

resource "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = [var.address_space]
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = local.subnet_names[each.key]
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegation_name != null ? [1] : []
    content {
      name = each.value.delegation_name
      service_delegation {
        name    = each.value.delegation_name
        actions = [each.value.delegation_action]
      }
    }
  }
}

resource "azurerm_network_security_group" "subnets" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = local.rg_name
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "subnets" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
}

# Hub-spoke peering (optional)
resource "azurerm_virtual_network_peering" "to_hub" {
  count = var.hub_vnet_id != null ? 1 : 0

  name                      = "peer-${var.workload}-${var.environment}-to-hub"
  resource_group_name       = local.rg_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.hub_vnet_id
  use_remote_gateways       = var.use_remote_gateways
  allow_forwarded_traffic   = true
}
```

### `outputs.tf`
```hcl
output "vnet_id" {
  description = "Resource ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet key to subnet resource ID"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet key to NSG resource ID"
  value       = { for k, v in azurerm_network_security_group.subnets : k => v.id }
}
```

## Hub Peering (from hub side)

When configuring the hub → spoke peering, set `allow_gateway_transit = true`:

```hcl
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-${spoke_name}"
  resource_group_name       = local.hub_rg_name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = spoke_vnet_id
  allow_gateway_transit     = true
  allow_forwarded_traffic   = true
}
```

Use a `terraform_data` resource if spokes depend on the VPN gateway being provisioned first:

```hcl
resource "terraform_data" "vpn_gateway_ready" {
  input = azurerm_virtual_network_gateway.this.id
}
```

Then reference it in the spoke peering module to create an implicit dependency.
