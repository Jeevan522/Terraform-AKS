variable rg_location {
  default = "East Asia"
}

variable virtual_network_name {
  default = "k8s-VN"
}

variable aks_subnet_name {
  default = "k8s-subnet"
}

variable virtual_network_address_prefix {
  default = "10.240.0.0/16"
}

variable aks_subnet_address_prefix {
  default = "10.240.1.0/24"
}

variable agw_subnet_name {
  default = "appgwsubnet"
}

variable agw_subnet_address_prefix {
  default = "10.240.2.0/24"
}
variable aks-name {
    default = "aks-sample"
}

variable kubernetes_version{
    default = "1.22.4"
}

variable dns_prefix {
  default = "aks-sample-1"
}

variable node_resource_group {
  default = "k8s-NSR"
}

variable client_id {
  default = "b23e510f-229b-4321-bce7-4dc46ce22c1d"
}

variable client_secret {
  default = "5xc8Q~YWpmEKBZvwZtYTNXj.ouxD0KeaGDSVtc8X"
}

variable app_gateway_name {
    default = "k8s-agw"
}

variable app_gateway_sku {
    default = "agw-sku"
}

variable gateway_ip_config {
    default = "appGatewayIpConfig"
}

variable http_Port {
    default = "http"
}