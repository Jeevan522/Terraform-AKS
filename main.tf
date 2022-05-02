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

# Virtual Network with subnet: 1 AKS & 1 AGW
resource "azurerm_virtual_network" "k8s-network" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix
  }

   subnet {
     name           = var.agw_subnet_name
     address_prefix = var.agw_subnet_address_prefix
   }

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

data "azurerm_subnet" "agwsubnet" {
  name                 = var.agw_subnet_name
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
# Azure Kubernetes Service

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
  
  
  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_D2_v2"
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
    # kube_dashboard {
    #   enabled = true
    # }
  }
  depends_on = [azurerm_virtual_network.k8s-network]
  #depends_on = [azurerm_virtual_network.ems-network, azurerm_application_gateway.ems-gateway]

  # tags = {
  #   Environment = default
  # }
}

# PIP Attaching to AGW

resource "azurerm_public_ip" "awg-pip" {

  name                = "pip-k8s-agw"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
  allocation_method   = "Static"
  sku                 = "Standard"
}
# Application Gateway
# URL https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway

locals {
    backend_address_pool_name      = "${azurerm_virtual_network.k8s-network.name}-beap"
    frontend_port_name             = "${azurerm_virtual_network.k8s-network.name}-feport"
    frontend_ip_configuration_name = "${azurerm_virtual_network.k8s-network.name}-feip"
    http_setting_name             = "${azurerm_virtual_network.k8s-network.name}-be-htst"
    listener_name                  = "${azurerm_virtual_network.k8s-network.name}-httpslstn"
    request_routing_rule_name      = "${azurerm_virtual_network.k8s-network.name}-rqrt"
    app_gateway_subnet_name        =  var.agw_subnet_name
}

resource "azurerm_application_gateway" "agw" {
  # for_each = {
  #   for key, value in var.ems_app_gateway : key => value if value["fqdn"] != null
  # }
  name                = var.app_gateway_name
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name

  sku {
    name     = var.app_gateway_sku
    tier     = "WAF_v2"
    capacity = 2
  }
  
  /*ssl_certificate {
    name     = "ems-host-server-b"
    key_vault_secret_id = "https://kvemsdevops-dev.vault.azure.net/secrets/ems-host-server-b/af98cc964ef54976a3f400c0d67b0507"
	
  } data     = filebase64("../release-scripts/ems-host-server-b.pem")*/
  
  # ssl_certificate{
  #   name     = "ems-host-server-b"
	# data     = filebase64("../release-scripts/ems-host-server-b.pfx")
	# password = "Otis@123"
  # }

  gateway_ip_configuration {
    name      = var.gateway_ip_config
    subnet_id = data.azurerm_subnet.agwsubnet.id
  }

  frontend_port {
    name = local.frontend_port_name                 
    port = 80
  }

  # frontend_port {
  #   name = "httpsPort"
  #   port = 443
  # }


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name    
  	public_ip_address_id = azurerm_public_ip.awg-pip.id
	
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    # port                  = 443
    # protocol              = "Https"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
	  probe_name            = "probe"
  }
  
  probe {
    name                = "probe"
    protocol            = "http"
    path                = "/"
    host                = "127.0.0.1"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "http"
	  #ssl_certificate_name           = "ems-host-server-b"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  # tags = {
  #   Environment = local.environment
  # } 

  depends_on = [azurerm_virtual_network.k8s-network, azurerm_public_ip.awg-pip]
}

# User Assigned Identity
resource "azurerm_user_assigned_identity" "test_identity" {
  name = "identity"
  location            = azurerm_resource_group.rg-k8s.location
  resource_group_name = azurerm_resource_group.rg-k8s.name
}
