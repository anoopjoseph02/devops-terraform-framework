variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure location for all resources"
  type        = string
}

variable "storage" {
  description = "Configuration for the storage account"
  type = object({
    name                     = string
    account_replication_type = string
  })
}

