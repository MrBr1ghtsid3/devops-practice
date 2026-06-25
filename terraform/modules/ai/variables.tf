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
  description = "Azure region. Azure OpenAI is not available in all regions — verify before applying."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
