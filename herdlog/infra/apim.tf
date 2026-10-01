# HerdLog lab - Step 7: API Management, the front door.
#
#   caller ──► APIM (key? real token? under the limit?) ──► Function
#
#   caller sends:  Ocp-Apim-Subscription-Key  +  Authorization: Bearer <token>
#   APIM adds:     x-functions-key  (the caller never sees it)

# --- The APIM service. Consumption = serverless, pay per call,
#     first 1 million calls a month free. ---
resource "azurerm_api_management" "apim" {
  name                = "apim-herdlog-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  publisher_name      = "HerdLog Lab"
  publisher_email     = var.publisher_email
  sku_name            = "Consumption_0" # Consumption always has capacity 0
  tags                = var.tags
}

# --- Read the Function's default key, so APIM can pass it on.
#     (Terraform state will contain it in plain text - one reason state
#     files never go into Git.) ---
data "azurerm_function_app_host_keys" "func" {
  name                = azurerm_function_app_flex_consumption.func.name
  resource_group_name = data.azurerm_resource_group.rg.name
}

# --- Store that key inside APIM as an encrypted "named value". ---
resource "azurerm_api_management_named_value" "func_key" {
  name                = "herdlog-func-key"
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "herdlog-func-key" # the policy refers to it as {{herdlog-func-key}}
  value               = data.azurerm_function_app_host_keys.func.default_function_key
  secret              = true
}

# --- The API as the outside world sees it:
#     https://<apim>.azure-api.net/herdlog/...  ──►  https://<func>/api/... ---
resource "azurerm_api_management_api" "herdlog" {
  name                  = "herdlog"
  resource_group_name   = data.azurerm_resource_group.rg.name
  api_management_name   = azurerm_api_management.apim.name
  revision              = "1"
  display_name          = "HerdLog API"
  path                  = "herdlog"
  protocols             = ["https"]
  service_url           = "https://${azurerm_function_app_flex_consumption.func.default_hostname}/api"
  subscription_required = true
}

# --- One operation: GET /herds. Anything else APIM answers with 404. ---
resource "azurerm_api_management_api_operation" "get_herds" {
  operation_id        = "get-herds"
  api_name            = azurerm_api_management_api.herdlog.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name
  display_name        = "Get herds"
  method              = "GET"
  url_template        = "/herds"

  response {
    status_code = 200
  }
}

# --- The rulebook (policies/herdlog-api.xml.tftpl), with our IDs filled in. ---
resource "azurerm_api_management_api_policy" "herdlog" {
  api_name            = azurerm_api_management_api.herdlog.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.rg.name

  xml_content = templatefile("${path.module}/policies/herdlog-api.xml.tftpl", {
    tenant_id        = var.external_tenant_id
    tenant_subdomain = var.external_tenant_subdomain
    api_client_id    = var.api_client_id
    rate_limit       = var.rate_limit_calls_per_minute
  })

  # The policy refers to the named value, so it must exist first.
  depends_on = [azurerm_api_management_named_value.func_key]
}

# --- Step 9: the GLOBAL rulebook (policies/global.xml) - applies to all APIs
#     and to URLs that match no API. Adds the HSTS header ZAP asked for. ---
resource "azurerm_api_management_policy" "global" {
  api_management_id = azurerm_api_management.apim.id
  xml_content       = file("${path.module}/policies/global.xml")
}

# --- A subscription key for us, the lab tester. In a real system the
#     HerdLog web app would hold one of these. ---
resource "azurerm_api_management_subscription" "lab" {
  display_name        = "herdlog-lab-tester"
  resource_group_name = data.azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  api_id              = "${azurerm_api_management.apim.id}/apis/${azurerm_api_management_api.herdlog.name}"
  state               = "active" # default is "submitted", which would not work
  allow_tracing       = false    # tracing can expose backend details
}
