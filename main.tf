terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
      resource_group_name  = "emstrstate"
      storage_account_name = "emstrstate15482"
      container_name       = "devops"
      key                  = "terraform.tfstate"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "rg-aks" {
  name     = "AKS-RG"
  location = var.rg_location
}