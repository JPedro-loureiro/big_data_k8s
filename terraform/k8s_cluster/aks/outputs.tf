resource "local_file" "kubeconfig" {
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
  filename   = "kubeconfig"
  content    = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
}

output "load_balancer_ip" {
  description = "The Ingress AKS Cluster IP"
  value = azurerm_public_ip.load_balancer_ip.ip_address
}

output "aks_cluster_name" {
  description = "The Ingress AKS Cluster IP"
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_resource_group_name" {
  description = "The Ingress AKS Cluster IP"
  value = azurerm_kubernetes_cluster.aks_cluster.resource_group_name
}

output "aks_cluster_node_resource_group_name" {
  description = "The Ingress AKS Cluster IP"
  value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}