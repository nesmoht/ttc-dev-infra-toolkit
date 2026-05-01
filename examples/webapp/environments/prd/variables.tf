variable "subscription_id" {
  description = "Azure subscription ID for dev environment"
  type        = string
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
