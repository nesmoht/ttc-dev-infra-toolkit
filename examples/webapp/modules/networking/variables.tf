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
  description = "Instance number for resource naming"
  type        = string
  default     = "001"
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "address_space" {
  description = "VNet address space CIDR"
  type        = string
}

variable "subnets" {
  description = "Map of subnet key to CIDR and optional service endpoints"
  type = map(object({
    cidr              = string
    service_endpoints = optional(list(string), [])
  }))
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for peering (optional)"
  type        = string
  default     = null
}

variable "use_remote_gateways" {
  description = "Route traffic through hub VPN gateway"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
