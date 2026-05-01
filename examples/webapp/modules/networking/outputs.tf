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
