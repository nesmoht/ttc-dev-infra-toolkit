output "storage_account_id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "sql_server_id" {
  description = "Resource ID of the SQL server"
  value       = azurerm_mssql_server.this.id
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL server"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "Resource ID of the SQL database"
  value       = azurerm_mssql_database.this.id
}
