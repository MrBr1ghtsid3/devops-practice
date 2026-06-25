resource "azurerm_virtual_desktop_host_pool" "this" {
  name                     = "${var.name_prefix}-avd-hp"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  type                     = var.host_pool_type
  load_balancer_type       = var.load_balancer_type
  maximum_sessions_allowed = var.max_sessions_allowed
  start_vm_on_connect      = var.start_vm_on_connect
  validate_environment     = var.validate_environment
  tags                     = var.tags
}

# expiration_date changes every plan (timestamp() is re-evaluated).
# Acceptable for sbox; for prod consider adding lifecycle { ignore_changes = [expiration_date] }
# once the initial apply has succeeded.
resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.this.id
  expiration_date = var.registration_expiration
}

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = "${var.name_prefix}-avd-dag"
  resource_group_name = var.resource_group_name
  location            = var.location
  host_pool_id        = azurerm_virtual_desktop_host_pool.this.id
  type                = var.application_group_type
  tags                = var.tags
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = "${var.name_prefix}-avd-ws"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = azurerm_virtual_desktop_workspace.this.id
  application_group_id = azurerm_virtual_desktop_application_group.this.id
}

resource "azurerm_network_interface" "session_host" {
  for_each = var.session_hosts

  name                = "${var.name_prefix}-${each.key}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "session_host" {
  for_each = var.session_hosts

  name                = "${var.name_prefix}-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = each.value.size
  admin_username      = each.value.admin_username
  # TODO: replace with a Key Vault data source reference — never inline passwords.
  # See ADR-003 for the identity / domain-join model that drives the KV access pattern.
  admin_password = var.admin_password

  network_interface_ids = [azurerm_network_interface.session_host[each.key].id]

  # TODO: identity block — Entra-joined vs AD DS / Entra DS domain-joined changes
  # this config materially. Decision deferred to ADR-003.
  # identity {
  #   type = "SystemAssigned"
  # }

  os_disk {
    # TODO: validate caching/storage tier against AVD workload profile
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    # TODO: evaluate AVD-optimised marketplace image or a custom golden image
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-23h2-avd"
    version   = "latest"
  }

  tags = var.tags
}

# TODO: azurerm_virtual_machine_extension — AVD agent + DSC registration
# The extension downloads the AVD agent and uses registration_token (from
# azurerm_virtual_desktop_host_pool_registration_info.this.token) to join each
# session host to the host pool. Check the current Microsoft-published artifact
# version in the Azure docs at implementation time — do not trust cached versions.
