name_prefix = "prod"
location    = "uksouth"

vnet_address_space = ["10.20.0.0/16"]

subnets = {
  compute = { address_prefix = "10.20.1.0/24" }
  data    = { address_prefix = "10.20.2.0/24" }
  app     = { address_prefix = "10.20.3.0/24" }
}

compute_subnet_name = "compute"

virtual_machines = {
  vm01 = { size = "Standard_D2s_v5" }
  vm02 = { size = "Standard_D2s_v5" }
}

admin_username = "azureuser"

tags = {
  environment = "prod"
  managed-by  = "terraform"
}

avd_subnet_key     = "app"
avd_host_pool_type = "Pooled"
avd_max_sessions   = 10

avd_session_hosts = {
  sh01 = { size = "Standard_D4s_v5", admin_username = "avdadmin" }
  sh02 = { size = "Standard_D4s_v5", admin_username = "avdadmin" }
}

# subscription_id, admin_ssh_public_key, and avd_admin_password are intentionally absent —
# pass via TF_VAR_* environment variables or CI secrets.
