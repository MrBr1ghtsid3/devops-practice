# Which Terraform and which providers this project needs.

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.7" # latest major on the Registry as of Sept 2026
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6" # used only to make globally unique names
    }
  }
}

provider "azurerm" {
  features {}

  # Required since provider 4.0: which subscription to build in.
  subscription_id = var.subscription_id

  # Provider 5.0 changed the default: it no longer registers ~60 resource
  # providers for you. We register only the ones this lab uses.
  # NOTE: registration takes minutes and Terraform may not wait for it.
  # Register new ones first with: az provider register --namespace X --wait
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Web",                 # Function App + its plan
    "Microsoft.Storage",             # storage account the Function needs
    "Microsoft.Insights",            # Application Insights
    "Microsoft.OperationalInsights", # Log Analytics workspace
    "Microsoft.ApiManagement",       # APIM (Step 7)
  ]
}
