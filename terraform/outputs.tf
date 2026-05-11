output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_name" {
  value = azurerm_virtual_network.aj-vnet.name
}

output "subnet_name" {
  value = azurerm_subnet.aj-aks-subnet.name
}

output "storage_account_name" {
  value = azurerm_storage_account.ajstorageacct445.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aj-aks.name
}

output "key_vault_name" {
  value = azurerm_key_vault.aj-keyvault2345.name
}

output "container_registry_name" {
  value = azurerm_container_registry.ajacr.name
}
