variable "resource_group" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The Azure region for the resources"
}

variable "storage" {
  type = object({
    name                     = string
    account_replication_type = string
  })
  description = "Storage account configuration"
}

