# HerdLog lab — Step 6: the Function and what it needs to run.
#
#   Log Analytics ◄── App Insights ◄── Function App (Flex, .NET 10)
#                                           │
#                                 Storage account (code package)

# --- The resource group already exists (the tenant wizard made it). ---
# "data" = read it, don't own it. Terraform will never delete it.
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# --- A short random suffix, because storage and function names must be
#     unique across all of Azure. ---
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  suffix = random_string.suffix.result
}

# --- Where logs are stored. ---
resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-herdlog-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "PerGB2018" # pay per GB after the 5 GB/month free allowance
  retention_in_days   = 30
  daily_quota_gb      = 0.1 # hard cap: ~3 GB/month max, stays inside the free 5 GB
  tags                = var.tags
}

# --- App Insights: the Function's logs, errors and timings.
#     Stores its data in the workspace above. ---
resource "azurerm_application_insights" "appi" {
  name                = "appi-herdlog-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}

# --- Storage: Flex Consumption keeps the deployed code package here. ---
resource "azurerm_storage_account" "st" {
  name                     = "stherdlog${local.suffix}" # lowercase letters/numbers only
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # cheapest: 3 copies in one datacentre
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "deploy" {
  name                  = "deploymentpackage"
  storage_account_id    = azurerm_storage_account.st.id
  container_access_type = "private"
}

# --- The plan: FC1 = Flex Consumption (serverless, pay per use). ---
resource "azurerm_service_plan" "plan" {
  name                = "asp-herdlog-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  os_type             = "Linux" # Flex is Linux-only
  sku_name            = "FC1"
  tags                = var.tags
}

# --- The Function App itself. ---
resource "azurerm_function_app_flex_consumption" "func" {
  name                = "func-herdlog-${local.suffix}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.plan.id

  # .NET 10 on the isolated worker model (supported until Nov 2028).
  runtime_name    = "dotnet-isolated"
  runtime_version = "10.0"

  # Where the code package lives, and how the app reaches it.
  # LAB SHORTCUT: a storage key. Production would use the app's managed
  # identity instead ("SystemAssignedIdentity"), so no key exists to leak.
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.st.primary_blob_endpoint}${azurerm_storage_container.deploy.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.st.primary_access_key

  # Keep it small: smallest memory size = fewer GB-seconds used from the
  # free grant; low scale-out ceiling = no runaway bill.
  instance_memory_in_mb  = 512
  maximum_instance_count = 40

  https_only = true

  site_config {
    application_insights_connection_string = azurerm_application_insights.appi.connection_string
  }

  tags = var.tags
}
