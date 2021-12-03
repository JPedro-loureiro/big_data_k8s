resource "local_file" "kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
  filename   = "kubeconfig"
  content    = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
}

output "Ingress_Cluster_IP" {
  description = "The Ingress AKS Cluster IP"
  value       = azurerm_public_ip.aks_ingress_ip.ip_address
}
