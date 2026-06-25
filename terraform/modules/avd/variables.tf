variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID (from the networking module) for session-host NICs."
}

variable "host_pool_type" {
  type        = string
  default     = "Pooled"
  description = "AVD host pool type — Pooled or Personal."

  validation {
    condition     = contains(["Pooled", "Personal"], var.host_pool_type)
    error_message = "host_pool_type must be Pooled or Personal."
  }
}

variable "load_balancer_type" {
  type        = string
  default     = "BreadthFirst"
  description = "Load balancer type — BreadthFirst or DepthFirst (Pooled); Persistent (Personal)."
}

variable "max_sessions_allowed" {
  type        = number
  description = "Maximum concurrent user sessions per session host."
}

variable "start_vm_on_connect" {
  type        = bool
  default     = false
  description = "Start a stopped session host when a user connects."
}

variable "validate_environment" {
  type        = bool
  default     = false
  description = "Whether this host pool receives AVD service updates before GA rollout."
}

variable "registration_expiration" {
  type        = string
  description = "RFC3339 datetime after which the registration token expires. Use timeadd(timestamp(), \"4h\") in the calling environment."
}

variable "application_group_type" {
  type        = string
  default     = "Desktop"
  description = "Application group type — Desktop or RemoteApp."

  validation {
    condition     = contains(["Desktop", "RemoteApp"], var.application_group_type)
    error_message = "application_group_type must be Desktop or RemoteApp."
  }
}

variable "session_hosts" {
  type = map(object({
    size           = string
    admin_username = string
  }))
  description = "Map of session host key to configuration. Key is used in resource names."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for session host VMs. Pass via TF_VAR_avd_admin_password or CI secret. TODO: replace with Key Vault data source reference."
}
