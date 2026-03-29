output "host" {
  value = azurerm_kubernetes_cluster.cluster.kube_config[0].host
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate
}

output "client_key" {
  value = azurerm_kubernetes_cluster.cluster.kube_config[0].client_key
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.cluster.oidc_issuer_url
}

output "principal_id" {
  value = azurerm_kubernetes_cluster.cluster.identity[0].principal_id
}
