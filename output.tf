output "aks_subnet_id" {
  value = data.azurerm_subnet.kubesubnet.id
}

output "agw_subnet_id" {
  value = data.azurerm_subnet.agwsubnet.id
}