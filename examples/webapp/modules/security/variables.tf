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
  description = "Short region code used in naming"
  type        = string
  default     = "sdc"
}

variable "resource_group_name" {
  description = "Name of the resource group to deploy into"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the Key Vault private endpoint (required in prd)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
