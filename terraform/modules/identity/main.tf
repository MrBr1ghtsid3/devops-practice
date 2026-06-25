# TODO: implement
# Suggested resources:
#   azurerm_user_assigned_identity        — one identity per environment principal
#   azurerm_federated_identity_credential — OIDC trust for GitHub Actions
#   azurerm_role_assignment               — Contributor (or narrower) on the subscription

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.name_prefix}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
