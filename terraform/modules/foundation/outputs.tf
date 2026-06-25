output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Name of the provisioned resource group."
}

output "resource_group_id" {
  value       = azurerm_resource_group.this.id
  description = "ID of the provisioned resource group."
}

output "location" {
  value       = azurerm_resource_group.this.location
  description = "Azure region of the resource group."
}
