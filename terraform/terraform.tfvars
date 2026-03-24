```hcl
resource_group = "my-rg"
location       = "eastus"

network = {
  virtual_network_name = "myVNet"
  subnet_name          = "mySubnet"
  address_space        = ["10.0.0.0/16"]
  subnet_prefix        = "10.0.1.0/24"
}

aks = {
  name      = "myAKSCluster"
  node_count = 2
}

storage = {
  name = "mystorageacct"
}
```

### Module: `modules/resource_group/main.tf`
```hcl
resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
}
```

### Module: `modules/resource_group/variables.tf`
```hcl
variable "name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for the resource group"
  type        = string
}
```

### Module: `modules/resource_group/outputs.tf`
```hcl
output "id" {
  value = azurerm_resource_group.this.id
}

output "name" {
  value = azurerm_resource_group.this.name
}
```

### Module: `modules/network/main.tf`
```hcl
resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "this" {
  name                  = var.subnet_name
  resource_group_name   = var.resource_group_name
  virtual_network_name  = azurerm_virtual_network.this.name
  address_prefixes      = [var.subnet_prefix]
}
```

### Module: `modules/network/variables.tf`
```hcl
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "subnet_prefix" {
  description = "The address prefix for the subnet"
  type        = string
}
```

### Module: `modules/network/outputs.tf`
```hcl
output "subnet_id" {
  value = azurerm_subnet.this.id
}
```

### Module: `modules/aks/main.tf`
```hcl
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  agent_pool_profile {
    name       = "agentpool"
    count      = var.node_count
    vm_size    = "Standard_DS2_v2"
    os_type    = "Linux"
    subnet_id  = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }
}
```

### Module: `modules/aks/variables.tf`
```hcl
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for resources"
  type        = string
}

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the AKS cluster"
  type        = number
}

variable "subnet_id" {
  description = "The ID of the subnet for AKS"
  type        = string
}
```

### Module: `modules/aks/outputs.tf`
```hcl
output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}
```

### Module: `modules/storage/main.tf`
```hcl
resource "azurerm_storage_account" "this" {
  name                     = lower(var.storage_account_name)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type  = "LRS"

  tags = {
    environment = "production"
  }
}
```

### Module: `modules/storage/variables.tf`
```hcl
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for resources"
  type        = string
}

variable "storage_account_name" {
  description = "The unique name of the storage account"
  type        = string
}
```

### Module: `modules/storage/outputs.tf`
```hcl
output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "name" {
  value = azurerm_storage_account.this.name
}
```

### How to Deploy
1. Navigate to the directory containing your main `*.tf` files.
2. Run `terraform init` to initialize the directory.
3. Run `terraform plan` to review the infrastructure changes.
4. Run `terraform apply` to create the resources in Azure.

This structured approach allows for clear organization and reusability of Terraform code, making it production-ready.
