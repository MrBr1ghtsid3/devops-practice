variable "subscription_id" {
  type        = string
  description = "Azure subscription ID. Pass via TF_VAR_subscription_id or -var; do not commit."
}

variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space CIDR(s) for the virtual network."
}

variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
  description = "Subnet definitions passed to the networking module."
}

variable "compute_subnet_name" {
  type        = string
  description = "Key from var.subnets that VMs are placed into."
}

variable "virtual_machines" {
  type = map(object({
    size = string
  }))
  description = "VM definitions passed to the compute module."
}

variable "admin_username" {
  type        = string
  description = "Admin username for all VMs."
}

variable "admin_ssh_public_key" {
  type        = string
  sensitive   = true
  description = "SSH public key for VM admin user. Pass via TF_VAR_admin_ssh_public_key or secrets."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags applied to all resources."
}

variable "avd_subnet_key" {
  type        = string
  description = "Key from var.subnets that AVD session hosts are placed into."
}

variable "avd_host_pool_type" {
  type        = string
  default     = "Pooled"
  description = "AVD host pool type — Pooled or Personal."
}

variable "avd_max_sessions" {
  type        = number
  description = "Maximum concurrent sessions per session host."
}

variable "avd_session_hosts" {
  type = map(object({
    size           = string
    admin_username = string
  }))
  description = "Session host definitions passed to the avd module."
}

variable "avd_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for AVD session hosts. Pass via TF_VAR_avd_admin_password; never commit."
}
