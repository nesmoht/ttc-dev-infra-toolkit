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

variable "storage_instance" {
  description = "Instance suffix for storage account name (3 chars, lowercase alphanumeric)"
  type        = string
  default     = "001"
}

variable "sql_aad_admin_login" {
  description = "Azure AD admin login name for SQL Server"
  type        = string
}

variable "sql_aad_admin_object_id" {
  description = "Azure AD object ID of the SQL admin user or group"
  type        = string
  sensitive   = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoints (required in prd)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
