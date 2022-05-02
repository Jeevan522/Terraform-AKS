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
  default = "k8s"
}

variable client_id {
  default = "b23e510f-229b-4321-bce7-4dc46ce22c1d"
}

variable client_secret {
  default = "027e96c1-faeb-4436-83b9-de4afe9e31ff"
}