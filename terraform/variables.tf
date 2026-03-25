variable "resource_group" {
  description = "The name of the Resource Group"
  type        = string
}

variable "location" {
  description = "The Azure location for all resources"
  type        = string
}

variable "storage" {
  description = "Storage account configuration"
  type = object({
    name                     = string
    account_replication_type = string
  })
}

