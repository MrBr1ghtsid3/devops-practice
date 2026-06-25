# Uncomment and populate before first apply.
# State must be in a container separate from sbox.
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstateprod<unique-suffix>"
#     container_name       = "tfstate-prod"
#     key                  = "prod.tfstate"
#     use_oidc             = true
#   }
# }
