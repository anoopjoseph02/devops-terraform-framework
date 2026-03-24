```hcl
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = module.resource_group.id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.name
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.storage.name
}
```

