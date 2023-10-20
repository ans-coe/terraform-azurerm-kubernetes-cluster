############################
# Azure Kubernetes cluster
############################

output "id" {
  description = "Resource ID of the Azure Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.main.id
}

output "location" {
  description = "Location of the Azure Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.main.location
}

output "name" {
  description = "Name of the Azure Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.main.name
}

output "node_resource_group_name" {
  description = "Name of the Azure Kubernetes cluster resource group."
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "identity" {
  description = "Azure Kubernetes cluster identity."
  value       = one(azurerm_kubernetes_cluster.main.identity)
}

output "kubelet_identity" {
  description = "Azure Kubernetes cluster kubelet identity."
  value       = one(azurerm_kubernetes_cluster.main.kubelet_identity)
}

output "oidc_issuer_url" {
  description = "The OIDC Issuer url of the cluster."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "kube_config" {
  description = "Azure Kubernetes cluster configuration."
  value       = one(azurerm_kubernetes_cluster.main.kube_config)
}
