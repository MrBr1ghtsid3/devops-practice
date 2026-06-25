module "foundation" {
  source = "../../modules/foundation"

  name_prefix = var.name_prefix
  location    = var.location
  tags        = var.tags
}

module "networking" {
  source = "../../modules/networking"

  name_prefix         = var.name_prefix
  resource_group_name = module.foundation.resource_group_name
  location            = var.location
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  tags                = var.tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix          = var.name_prefix
  resource_group_name  = module.foundation.resource_group_name
  location             = var.location
  subnet_id            = module.networking.subnet_ids[var.compute_subnet_name]
  virtual_machines     = var.virtual_machines
  admin_username       = var.admin_username
  admin_ssh_public_key = var.admin_ssh_public_key
  tags                 = var.tags
}

module "avd" {
  source = "../../modules/avd"

  name_prefix             = var.name_prefix
  resource_group_name     = module.foundation.resource_group_name
  location                = var.location
  subnet_id               = module.networking.subnet_ids[var.avd_subnet_key]
  host_pool_type          = var.avd_host_pool_type
  max_sessions_allowed    = var.avd_max_sessions
  session_hosts           = var.avd_session_hosts
  admin_password          = var.avd_admin_password
  registration_expiration = timeadd(timestamp(), "4h")
  tags                    = var.tags
}
