output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Resource ID of the virtual network."
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "Name of the virtual network."
}

output "subnet_ids" {
  value       = { for k, v in azurerm_subnet.this : k => v.id }
  description = "Map of subnet name to subnet resource ID."
}

output "nsg_ids" {
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
  description = "Map of subnet name to NSG resource ID."
}
