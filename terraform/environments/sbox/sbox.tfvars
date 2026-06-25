name_prefix = "dev"
location    = "uksouth"

vnet_address_space = ["10.10.0.0/16"]

subnets = {
  compute = { address_prefix = "10.10.1.0/24" }
  data    = { address_prefix = "10.10.2.0/24" }
  app     = { address_prefix = "10.10.3.0/24" }
}

compute_subnet_name = "compute"

virtual_machines = {
  vm01 = { size = "Standard_B1s" }
}

admin_username = "azureuser"

tags = {
  environment = "sbox"
  managed-by  = "terraform"
}

avd_subnet_key     = "app"
avd_host_pool_type = "Pooled"
avd_max_sessions   = 2

avd_session_hosts = {
  sh01 = { size = "Standard_B2ms", admin_username = "avdadmin" }
}

# subscription_id, admin_ssh_public_key, and avd_admin_password are intentionally absent —
# pass via TF_VAR_* environment variables or CI secrets.
