#################### Generic variables ####################

variable "region" {
  description = "Cloud region"
  type        = string
#   nullable    = false
}

variable "env" {
  description = "dev | qa | prod"
  type        = string
#   nullable    = false
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
#   nullable    = false
}

variable "main_node_type" {
  description = "Main node type"
  type        = string
#   nullable    = false
}

#################### AKS Variables ####################

variable "aks" {
  description = "Main node type"
  type        = bool
#   nullable    = false
}