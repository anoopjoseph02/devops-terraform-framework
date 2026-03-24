provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_storage_account" "example" {
  name                     = var.storage["name"]
  resource_group_name     = azurerm_resource_group.example.name
  location                = azurerm_resource_group.example.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
}

