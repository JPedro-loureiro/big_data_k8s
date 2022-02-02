#################### Kubernetes Provider ####################

provider "kubernetes" {
    host                   = var.host
    client_certificate     = var.client_certificate
    client_key             = var.client_key
    cluster_ca_certificate = var.cluster_ca_certificate
}

#################### ArgoCD Ingress ####################

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name = "argocd-server-ingress"
    namespace = "cicd"
    annotations = {
      "cert-manager.io/cluster-issuer" = "lets-encrypt-cluster-issuer"
      "kubernetes.io/ingress.class" = "nginx"
      "kubernetes.io/tls-acme" = "true"
      "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
  }
  spec {
    rule {
      host = "argocd.dev.bigdataonk8s.com"
      http {
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
    tls {
      hosts = [
        "argocd.dev.bigdataonk8s.com"
      ]
      secret_name = "argocd-secret"
    }
  }
}

#################### ArgoCD Project ####################

# The Big data on k8s ArgoCD Project
resource "kubernetes_manifest" "big_data_on_k8s_project" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"

    metadata = {
      name      = "big-data-on-k8s"
      namespace = "cicd"
    }

    spec = {
      description = "Big Data on k8s"

      sourceRepos = [
        "https://github.com/JPedro-loureiro/big_data_k8s",
        "https://strimzi.io/charts",
        "https://charts.bitnami.com/bitnami",
        "https://prometheus-community.github.io/helm-charts",
      ]

      destinations = [{
        namespace = "*"
        server    = "https://kubernetes.default.svc"
      }]

      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]

      orphanedResources = {
        warn = true
      }
    }
  }
}

#################### ArgoCD Applications ####################

# App Test
resource "kubernetes_manifest" "app_test_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "app-test"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path           = "apps/app_test"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "app-test"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }
}

# Data Gen
resource "kubernetes_manifest" "data_generator" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "data-generator"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path           = "apps/data_generator/k8s"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "data-generator"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }
}

# Strimzi Operator
resource "kubernetes_manifest" "strimzi_operator" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "strimzi-kafka-operator"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://strimzi.io/charts"
        targetRevision = "0.26.0"
        chart          = "strimzi-kafka-operator"
        helm = {
          version = "v3"
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "ingestion"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.big_data_on_k8s_project
  ]
}

# Kafka Cluster
resource "kubernetes_manifest" "kafka_cluster" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kafka-cluster"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path           = "apps/ingestion/kafka/kafka-cluster"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "ingestion"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.strimzi_operator
  ]
}

# Kafka Topics
resource "kubernetes_manifest" "kafka_topics" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kafka-topics"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://github.com/JPedro-loureiro/big_data_k8s"
        targetRevision = "HEAD"
        path           = "apps/ingestion/kafka/kafka-topics"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "ingestion"
      }

      syncPolicy = {
        automated = {
          prune      = true
          selfHeal   = true
          allowEmpty = false
        }

        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true"
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.kafka_cluster
  ]
}

# Prometheus Operator
resource "kubernetes_manifest" "kube-prometheus-stack" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "kube-prometheus-stack"
      namespace = "cicd"
    }

    spec = {
      project = "big-data-on-k8s"

      source = {
        repoURL        = "https://github.com/JPedro-loureiro/big_data_k8s"
        path          = "apps/monitoring/kube-prometheus-stack"
        targetRevision = "HEAD"
        # helm = {
        #   version = "v3"
        # }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "monitoring"
      }

      syncPolicy = {
        syncOptions = [
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "PruneLast=true",
          # "Replace=true", # kubectl replace insted of apply: resource spec might be too big and won't fit into kubectl.kubernetes.io/last-applied-configuration
        ]

        retry = {
          limit = 3
          backoff = {
            duration    = "5s"
            factor      = 2
            maxDuration = "1m"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_manifest.big_data_on_k8s_project
  ]
}