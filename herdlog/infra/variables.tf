variable "subscription_id" {
  description = "Subscription to build in. Set it in terraform.tfvars."
  type        = string
}

variable "location" {
  description = "Azure region for every resource."
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Existing resource group (the external tenant wizard creates one)."
  type        = string
  default     = "rg-herdlog-lab"
}

# --- Step 7: API Management ---

variable "publisher_email" {
  description = "Contact email APIM requires. Set it in terraform.tfvars."
  type        = string
}

variable "external_tenant_id" {
  description = "Tenant ID of the external (customer) tenant: the 'tid' claim in tokens."
  type        = string
}

variable "external_tenant_subdomain" {
  description = "The external tenant's sign-in subdomain: <subdomain>.ciamlogin.com."
  type        = string
}

variable "api_client_id" {
  description = "Client ID of the herdlog-api app registration: the 'aud' claim in tokens."
  type        = string
}

variable "rate_limit_calls_per_minute" {
  description = "Calls allowed per subscription key per minute before APIM returns 429."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Labels on every resource, so the lab is easy to find and clean up."
  type        = map(string)
  default = {
    project = "herdlog"
    purpose = "lab"
  }
}
