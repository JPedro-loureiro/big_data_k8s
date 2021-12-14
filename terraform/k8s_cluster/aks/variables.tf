variable "region" {
  description = "Azure region"
  type = string
  # nullable = false
}

variable "env" {
  description = "dev | qa | prod"
  type = string
  # nullable = false
}

variable "k8s_version" {
  description = "Kubernetes version"
  type = string
  # nullable = false
}

variable "default_node_type" {
  description = "Default node type"
  type = string
  # nullable = false
}