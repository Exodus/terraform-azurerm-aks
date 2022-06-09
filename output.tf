output "kube_admin_config" {
  description = "Kubernetes Admin Credentials"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.main.kube_admin_config
}
