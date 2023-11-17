output "kube_admin_config" {
  description = "Kubernetes Admin Credentials"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.main.kube_admin_config
}

output "oidc_issuer_url" {
  description = "The OIDC issuer URL that is associated with the cluster."
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
