output "function_app_name" {
  description = "Used by: func azure functionapp publish <name>"
  value       = azurerm_function_app_flex_consumption.func.name
}

output "herds_url" {
  description = "The GetHerds endpoint on the Function directly (Step 6)."
  value       = "https://${azurerm_function_app_flex_consumption.func.default_hostname}/api/herds"
}

output "app_insights_name" {
  value = azurerm_application_insights.appi.name
}

# --- Step 7 ---

output "apim_herds_url" {
  description = "The GetHerds endpoint through APIM - the front door."
  value       = "${azurerm_api_management.apim.gateway_url}/herdlog/herds"
}

output "apim_subscription_key" {
  description = "Lab subscription key. Read with: terraform output -raw apim_subscription_key"
  value       = azurerm_api_management_subscription.lab.primary_key
  sensitive   = true
}

# --- Read by tests/test-apim.sh to build its forged token. ---

output "external_tenant_id" {
  value = var.external_tenant_id
}

output "api_client_id" {
  value = var.api_client_id
}
