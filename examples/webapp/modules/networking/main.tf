locals {
  azure_reserved_subnets = [
    "GatewaySubnet",
    "AzureFirewallSubnet",
    "AzureBastionSubnet",
    "AppGatewaySubnet",
  ]

  vnet_name = "vnet-spk-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"

  subnet_names = {
    for k, _ in var.subnets : k =>
    contains(local.azure_reserved_subnets, k) ? k : "snet-${k}-${var.workload}-${var.environment}-${var.region_suffix}-${var.instance}"
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
  resource_group_name = var.resource_group_name
  address_space       = [var.address_space]
  tags                = local.common_tags
}

resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  name                 = local.subnet_names[each.key]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = each.value.service_endpoints
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

resource "azurerm_virtual_network_peering" "to_hub" {
  count = var.hub_vnet_id != null ? 1 : 0

  name                      = "peer-${var.workload}-${var.environment}-to-hub"
  resource_group_name       = var.resource_group_name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.hub_vnet_id
  use_remote_gateways       = var.use_remote_gateways
  allow_forwarded_traffic   = true
}
