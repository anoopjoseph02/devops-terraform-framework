```hcl
variable "resource_group" {
  type        = string
  description = "The name of the resource group."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}

variable "storage_name" {
  type        = string
  description = "The name of the Azure Storage Account."
}

variable "account_replication_type" {
  type        = string
  description = "The replication type of the Storage Account."
}
```
