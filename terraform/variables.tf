variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location for all resources"
  type        = string
}

variable "storage_name" {
  description = "The name of the storage account"
  type        = string
}

variable "storage_account_replication_type" {
  description = "The replication type for the storage account"
  type        = string
}

