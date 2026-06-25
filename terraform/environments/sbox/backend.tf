# Uncomment and populate before first apply.
# State must be in a container separate from prod.
#
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstatesbox<unique-suffix>"
#     container_name       = "tfstate-sbox"
#     key                  = "sbox.tfstate"
#     use_oidc             = true
#   }
# }
