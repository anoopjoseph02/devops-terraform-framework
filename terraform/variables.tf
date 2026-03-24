variable "resource_group" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The location where resources will be deployed."
  type        = string
}

variable "storage" {
  description = "Storage account configuration."
  type        = map(string)
}

