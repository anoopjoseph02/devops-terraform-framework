```hcl
variable "resource_group" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the resources"
  type        = string
}

variable "storage_name" {
  description = "Name of the storage account"
  type        = string
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
}
```
