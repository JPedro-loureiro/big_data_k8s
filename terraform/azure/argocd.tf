# helm repo add argok https://argoproj.github.io/argo-helm
data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = azurerm_kubernetes_cluster.aks_cluster.name
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.resource_group_name
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)

  }
}

resource "helm_release" "argocd" {
  name = "argocd"
  namespace = "cicd"
  create_namespace = true
  repository      = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

output "manifest" {
  value = helm_release.argocd.manifest
}