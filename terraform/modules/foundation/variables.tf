variable "name_prefix" {
  type        = string
  description = "Prefix applied to all resource names."
}

variable "location" {
  type        = string
  description = "Azure region for the resource group."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
