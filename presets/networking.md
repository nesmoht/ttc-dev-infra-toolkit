# Preset: Networking (Hub-Spoke)

Apply this preset when the project needs VNet, subnets, NSG, and/or hub-spoke peering.

## Module: `modules/networking/`

Create the following files:

### `versions.tf`
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
  description = "Short region code used in naming (e.g. we, ne)"
  type        = string
  default     = "we"
}

variable "address_space" {
  description = "VNet address space CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnets" {
  description = "Map of subnet names to CIDR prefixes"
  type        = map(string)
  default = {
    data             = "10.1.1.0/24"
    app              = "10.1.2.0/24"
    private-endpoints = "10.1.3.0/26"
  }
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for peering (optional)"
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
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.workload}-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = "snet-${each.key}-${var.workload}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "subnets" {
  for_each = var.subnets

  name                = "nsg-${each.key}-${var.workload}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
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

  name                      = "peer-${var.workload}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.hub_vnet_id
  use_remote_gateways       = false
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
  description = "Map of subnet name to subnet resource ID"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet name to NSG resource ID"
  value       = { for k, v in azurerm_network_security_group.subnets : k => v.id }
}
```
