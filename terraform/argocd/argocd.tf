# Get Azure provider
provider "azurerm" {
  features {}
}

# Get AKS cluster data
data "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

# Config kubernetes provider
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate)
}

#################### ArgoCD Project ####################

# The Big data on k8s ArgoCD Project
resource "kubernetes_manifest" "big_data_on_k8s_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name = "big-data-on-k8s"
      namespace = "cicd"
    }

    spec = {
      description = "Big Data on k8s"

      sourceRepos = [
        "https://github.com/JPedro-loureiro/big_data_k8s"
      ]

      destinations = [{
        namespace = "*"
        server = "https://kubernetes.default.svc"
      }]

      clusterResourceWhitelist = [{
        group = "*"
        kind = "*"
      }]

      orphanedResources = {
        warn = true
      }
    }
  }
}

#################### ArgoCD Applications ####################

# App Test application
resource "kubernetes_manifest" "app_test_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name = "app-test"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path = "app_test"
      }

      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "app-test"
      }

      syncPolicy = {
        automated = {
          prune = true
          selfHeal = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 5
          backoff = {
            duration = "5s"
            factor = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }
}

# Kafka application
resource "kubernetes_manifest" "kafka_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name = "kafka"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path = "kafka"
      }

      destination = {
        server = "https://kubernetes.default.svc"
        namespace = "ingestion"
      }

      syncPolicy = {
        automated = {
          prune = true
          selfHeal = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 5
          backoff = {
            duration = "5s"
            factor = 2
            maxDuration = "3m"
          }
        }
      }
    }
  }
}