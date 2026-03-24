```hcl
provider "azurerm" {
  features {}
}

module "resource_group" {
  source        = "./modules/resource_group"
  name          = var.resource_group
  location      = var.location
}

module "network" {
  source                  = "./modules/network"
  resource_group_name     = module.resource_group.name
  virtual_network_name    = var.network.virtual_network_name
  subnet_name             = var.network.subnet_name
  address_space           = var.network.address_space
  subnet_prefix           = var.network.subnet_prefix
}

module "aks" {
  source                   = "./modules/aks"
  resource_group_name      = module.resource_group.name
  location                 = var.location
  cluster_name             = var.aks.name
  node_count               = var.aks.node_count
  subnet_id                = module.network.subnet_id
}

module "storage" {
  source                = "./modules/storage"
  resource_group_name   = module.resource_group.name
  location              = var.location
  storage_account_name  = var.storage.name
}

output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_id" {
  value = module.aks.cluster_id
}

output "storage_account_id" {
  value = module.storage.storage_account_id
}
```

