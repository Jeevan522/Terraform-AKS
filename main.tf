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

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.k8s-network.name
  resource_group_name  = azurerm_resource_group.rg-k8s.name
  depends_on = [azurerm_virtual_network.k8s-network]
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "k8s-law" {
  name                = "log-k8s"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "ems-las" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.rg-k8s.location
  resource_group_name   = azurerm_resource_group.rg-k8s.name
  workspace_resource_id = azurerm_log_analytics_workspace.k8s-law.id
  workspace_name        = azurerm_log_analytics_workspace.k8s-law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
#AKS

resource "azurerm_kubernetes_cluster" "k8s-aks" {
  #for_each = var.ems_app_gateway

  name                = var.aks-name
  location            = var.rg_location
  resource_group_name = azurerm_resource_group.rg-k8s.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = var.node_resource_group


  # linux_profile {
  #   admin_username = "ubuntu"

  #   ssh_key {
  #     key_data = var.ssh_public_key
  #   }
  # }

  
  network_profile {
    network_plugin    = "azure"
  }
  
  # network_profile {
  #   network_plugin    = "kubenet"
  #   load_balancer_sku = "Standard"
  # }
  
  
  

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    #type       = "VirtualMachineScaleSets"
	  vnet_subnet_id  = data.azurerm_subnet.kubesubnet.id
	
  }
  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }
  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.k8s-law.id
    }
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = true
    }
  }
  depends_on = [azurerm_virtual_network.k8s-network]
  #depends_on = [azurerm_virtual_network.ems-network, azurerm_application_gateway.ems-gateway]

  tags = {
    Environment = default
  }
}