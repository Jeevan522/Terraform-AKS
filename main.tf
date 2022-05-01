 terraform {
   required_version = "=0.12.29"
  backend "azurerm" {
    resource_group_name  = "k8s"
    storage_account_name = "demo1storageaccount"
    container_name       = "devops"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  version = "~>2.0"
  features {}
  
}

# Resource Group
resource "azurerm_resource_group" "rg-k8s" {
  name     = "rg-k8s"
  location = var.rg_location
}

# Virtual Network
resource "azurerm_virtual_network" "k8s-network" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix
  }

  # subnet {
  #   name           = "appgwsubnet"
  #   address_prefix = var.app_gateway_subnet_address_prefix
  # }

  # tags = {
  #   Environment = local.environment
  # }
}