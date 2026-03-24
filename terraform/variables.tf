```hcl
variable "resource_group" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for resources"
  type        = string
}

variable "network" {
  description = "Network configuration"
  type = object({
    virtual_network_name = string
    subnet_name          = string
    address_space        = list(string)
    subnet_prefix        = string
  })
}

variable "aks" {
  description = "AKS configuration"
  type = object({
    name      = string
    node_count = number
  })
}

variable "storage" {
  description = "Storage account configuration"
  type = object({
    name = string
  })
}
```

