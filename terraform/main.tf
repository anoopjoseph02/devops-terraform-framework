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
  account_tier             = "Standard"
  account_replication_type = var.storage.account_replication_type
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_group}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.resource_group}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.resource_group}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.resource_group}-dns"

  agent_pool_profile {
    name    = "agentpool"
    count   = 3
    vm_size = "Standard_DS2_v2"
    os_type = "Linux"
  }

  identity {
    type = "SystemAssigned"
  }
}

