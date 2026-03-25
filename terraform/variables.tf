```hcl
variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "storage_name" {
  description = "The name of the storage account"
  type        = string
}

variable "account_replication_type" {
  description = "The replication type for the storage account"
  type        = string
}
```
