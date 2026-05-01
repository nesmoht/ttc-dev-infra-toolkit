output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Resource ID of the spoke VNet"
  value       = module.networking.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet key to subnet resource ID"
  value       = module.networking.subnet_ids
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.data.storage_account_name
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL server"
  value       = module.data.sql_server_fqdn
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}
