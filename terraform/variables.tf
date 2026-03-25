variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
}

variable "storage" {
  description = "Storage account configuration"
  type = object({
    name                     = string
    account_replication_type = string
  })
}

