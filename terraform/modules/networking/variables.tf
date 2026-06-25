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

variable "address_space" {
  type        = list(string)
  description = "CIDR block(s) for the virtual network address space."
}

variable "subnets" {
  type = map(object({
    address_prefix = string
  }))
  description = "Map of subnet name to address prefix. An NSG is created and associated for each entry."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
