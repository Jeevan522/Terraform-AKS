# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "=3.4.0"

#     }
#   }
# }

# # Configure the Microsoft Azure Provider
# provider "azurerm" {
#   features {}
# }


 terraform {
   required_version = "=1.1.9"
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

# Create a resource group
resource "azurerm_resource_group" "rg-k8s" {
  name     = "rg-k8s"
  location = var.rg_location
}