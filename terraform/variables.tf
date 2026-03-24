variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location for all resources"
  type        = string
}

variable "storage" {
  description = "Storage account configuration"
  type = object({
    name = string
  })
}

