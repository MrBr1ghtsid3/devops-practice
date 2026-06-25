output "host_pool_id" {
  value       = azurerm_virtual_desktop_host_pool.this.id
  description = "Resource ID of the AVD host pool."
}

output "host_pool_name" {
  value       = azurerm_virtual_desktop_host_pool.this.name
  description = "Name of the AVD host pool."
}

output "workspace_id" {
  value       = azurerm_virtual_desktop_workspace.this.id
  description = "Resource ID of the AVD workspace."
}

output "application_group_id" {
  value       = azurerm_virtual_desktop_application_group.this.id
  description = "Resource ID of the desktop application group."
}

output "registration_token" {
  value       = azurerm_virtual_desktop_host_pool_registration_info.this.token
  sensitive   = true
  description = "Registration token consumed by the AVD agent VM extension to join session hosts to the pool."
}

output "session_host_ids" {
  value       = { for k, v in azurerm_windows_virtual_machine.session_host : k => v.id }
  description = "Map of session host key to VM resource ID."
}
