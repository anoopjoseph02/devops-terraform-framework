variable "resource_group" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The location where resources will be created."
  type        = string
}

variable "storage" {
  description = "Configuration for the storage account."
  type = object({
    name = string
  })
}

