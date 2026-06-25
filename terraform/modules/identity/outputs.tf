output "identity_id" {
  value       = azurerm_user_assigned_identity.this.id
  description = "Resource ID of the user-assigned managed identity."
}

output "client_id" {
  value       = azurerm_user_assigned_identity.this.client_id
  description = "Client ID of the managed identity (used in OIDC federation)."
}

output "principal_id" {
  value       = azurerm_user_assigned_identity.this.principal_id
  description = "Principal ID for role assignments."
}
