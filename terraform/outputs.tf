```hcl
output "resource_group_id" {
  description = "The id of the resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_id" {
  description = "The id of the storage account"
  value       = azurerm_storage_account.main.id
}
```
