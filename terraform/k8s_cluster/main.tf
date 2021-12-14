terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.48.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.0"
    }
  }
}

#################### AKS ####################

provider "azurerm" {
  features {}
}

module "aks_cluster" {
  count             = var.aks == true ? 1 : 0
  source            = "./aks"
  region            = var.region
  env               = var.env
  k8s_version       = var.k8s_version
  default_node_type = var.main_node_type
}

data "azurerm_kubernetes_cluster" "aks_cluster" {
  count               = var.aks == true ? 1 : 0
  name                = module.aks_cluster[0].aks_cluster_name
  resource_group_name = module.aks_cluster[0].aks_cluster_resource_group_name
  depends_on = [
    module.aks_cluster
  ]
}

data "azurerm_public_ip" "aks_load_balancer_ip" {
  count               = var.aks == true ? 1 : 0
  name                = module.aks_cluster[0].load_balancer_ip
  resource_group_name = module.aks_cluster[0].aks_cluster_node_resource_group_name
  depends_on = [
    module.aks_cluster
  ]
}

#################### EKS ####################



#################### GKE ####################



#################### Nginx Ingress Controller ####################

module "big_data" {
  source = "./big_data"
  host = data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.host
  client_certificate = base64decode(data.azurerm_kubernetes_cluster[0].aks_cluster.kube_config.0.client_certificate)
  client_key = base64decode(data.azurerm_kubernetes_cluster.aks_cluster[0].kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster[0].aks_cluster.kube_config.0.cluster_ca_certificate)
  load_balancer_ip = data.azurerm_public_ip.aks_load_balancer_ip[0].ip_address
  env = var.env
}

#################### Cert-manager ####################



#################### ArgoCD ####################
