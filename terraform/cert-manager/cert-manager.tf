terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.48.0"
    }
  }
}

#################### Azure Provider ####################

provider "azurerm" {
  features {}
}

#################### AKS Cluster Data ####################

data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

#################### Ingress Public IP Data ####################

data "azurerm_public_ip" "aks_ingress_ip" {
  name = "aks-ingress-ip"
  resource_group_name = data.azurerm_kubernetes_cluster.aks_cluster.node_resource_group
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
      name = "lets-encrypt-cluster-issuer"
    }

    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "big_data_on_k8s@gmail.com"
        privateKeySecretRef = {
          name = "lets-encrypt-cluster-issuer-key"
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

#################### TLS Certificate ####################

resource "kubernetes_manifest" "tls_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name = "ingress-cert"
      namespace = "cert-manager"
    }

    spec = {
      secretName = "ingress-cert-secret"
      ipAddresses = [
        data.azurerm_public_ip.aks_ingress_ip.ip_address
      ]
      issuerRef = {
        name = "lets-encrypt-cluster-issuer"
        kind = "ClusterIssuer"
      }
    }
  }
  depends_on = [
    kubernetes_manifest.cluster_issuer
  ]
}
