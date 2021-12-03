#################### Azure Provider ####################

provider "azurerm" {
  features {}
}

#################### AKS Cluster Data ####################

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

#################### Kubernetes Provider ####################

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

#################### Let's Encrypt Issuer ####################

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsEncrypt-cluster-issuer"
    }

    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "big_data_on_k8s@gmail.com"
        privateKeySecretRef = {
          name = "letEncrypt-cluster-issuer-key"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  }
}

# 13:15