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