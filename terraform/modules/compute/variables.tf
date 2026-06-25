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

variable "subnet_id" {
  type        = string
  description = "Subnet ID (from the networking module) to attach NICs to."
}

variable "virtual_machines" {
  type = map(object({
    size = string
  }))
  description = "Map of VM key to configuration. Key is used in resource names."
}

variable "admin_username" {
  type        = string
  description = "Admin username for all VMs."
}

variable "admin_ssh_public_key" {
  type        = string
  sensitive   = true
  description = "SSH public key placed in the admin user's authorized_keys."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
