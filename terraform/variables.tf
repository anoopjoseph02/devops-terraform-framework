variable "resource_group" {
  description = "The name of the Resource Group"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "storage" {
  description = "Storage account settings"
  type        = map(string)
}

