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
    vm_size    = var.default_node_type # standard_b2s
  }

  identity {
    type = "SystemAssigned"
  }
}

#################### Node Pools ####################

# resource "azurerm_kubernetes_cluster_node_pool" "memory_optimized" {
#  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
#  name                  = "${var.env}memopt"
#  node_count            = "1"
#  vm_size               = "standard_d11_v2"
# }

#################### Public IP ####################

resource "azurerm_public_ip" "load_balancer_ip" {
  name                = "aks-ingress-ip"
  resource_group_name = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}