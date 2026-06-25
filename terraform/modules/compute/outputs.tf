output "vm_ids" {
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.id }
  description = "Map of VM key to resource ID."
}

output "vm_names" {
  value       = { for k, v in azurerm_linux_virtual_machine.this : k => v.name }
  description = "Map of VM key to resource name."
}

output "private_ip_addresses" {
  value       = { for k, v in azurerm_network_interface.this : k => v.private_ip_address }
  description = "Map of VM key to private IP address."
}
