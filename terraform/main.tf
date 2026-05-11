terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "aj-rg-prod"
  location = "eastus"

  tags = {
    project     = "ai-devops-framework"
    owner       = "anoop-joseph"
    cost_centre = "engineering"
  }
}

resource "azurerm_virtual_network" "aj-vnet" {
  name                = "aj-vnet"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "aj-aks-subnet" {
  name                 = "aj-aks-subnet"
  address_prefixes     = ["10.1.0.0/16"]
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.aj-vnet.name
}

resource "azurerm_storage_account" "ajstorageacct445" {
  name                     = "ajstorageacct445"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_kubernetes_cluster" "aj-aks" {
  name                = "aj-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name                   = "default"
    vm_size                = "Standard_D4s_v3"
    enable_auto_scaling    = true
    min_count              = 2
    max_count              = 5
    enable_node_public_ip  = false
    enable_host_encryption = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_key_vault" "aj-keyvault2345" {
  name                       = "aj-keyvault2345"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true

  tags = azurerm_resource_group.main.tags
}

resource "azurerm_container_registry" "ajacr" {
  name                = "ajacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = azurerm_resource_group.main.tags
}
