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

#################### Helm Provider ####################

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
  }
}

#################### Resource Group ####################

resource "azurerm_resource_group" "rg" {
  name     = "bigDataOnK8s"
  location = var.region
}

#################### AKS ####################

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.env}_aks_cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.env}-aks-cluster"
  kubernetes_version  = var.k8s_version

  node_resource_group = "bigDataOnK8s-nodeResourceGroup"

  default_node_pool {
    name       = "${var.env}master"
    node_count = "1"
    vm_size    = "standard_b2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Get AKS cluster data
data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = azurerm_kubernetes_cluster.aks_cluster.name
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.resource_group_name
}

#################### Node Pools ####################

# resource "azurerm_kubernetes_cluster_node_pool" "memory_optimized" {
#  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
#  name                  = "${var.env}memopt"
#  node_count            = "1"
#  vm_size               = "standard_d11_v2"
# }

#################### Public IP ####################

resource "azurerm_public_ip" "aks_ingress_ip" {
  name                = "aks-ingress-ip"
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

#################### Nginx Ingress Controller ####################

resource "helm_release" "nginx_ingress_controller" {
  name             = "nginx-ingress-controller"
  namespace        = "nginx-ingress-controller"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.aks_ingress_ip.ip_address
  }

  # To get de FQDN run:
  # az network public-ip list --resource-group bigDataOnK8s-nodeResourceGroup --query "[?name=='aks-ingress-ip'].[dnsSettings.fqdn]" -o tsv
  set {
    name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-dns-label-name\""
    value = "k8s-${var.env}"
  }
}

#################### ArgoCD ####################

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "cicd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
}

#################### Cert-manager Operator ####################

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"

  set {
    name  = "installCRDs"
    value = true
  }
}