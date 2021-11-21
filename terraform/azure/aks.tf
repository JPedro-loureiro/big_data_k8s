terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.48.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "bigDataOnK8s"
  location = var.region
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${var.env}_aks_cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.env}-aks-cluster"

  default_node_pool {
    name       = "${var.env}master"
    node_count = "1"
    vm_size    = "standard_b2s"
  }

  identity {
    type = "SystemAssigned"
  }

  addon_profile {
    http_application_routing {
      enabled = true
    }
  }
}

# resource "azurerm_kubernetes_cluster_node_pool" "memory_optimized" {
#  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
#  name                  = "${var.env}memopt"
#  node_count            = "1"
#  vm_size               = "standard_d11_v2"
# }