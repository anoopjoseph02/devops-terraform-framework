provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage.name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier            = "Standard"
  account_replication_type = var.storage.account_replication_type

  depends_on = [
    azurerm_resource_group.main
  ]
}

