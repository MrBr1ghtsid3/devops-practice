# Reference: canonical provider version constraints for all environments.
# This file is documentation only — Terraform does not evaluate it when running
# from an environment subdirectory. Each environment's providers.tf is authoritative.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}
