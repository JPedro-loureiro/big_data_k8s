variable "region" {
  default = "eastus"
}

variable "env" {
  description = "prod | dev"
  default     = "dev"
}

variable "k8s_version" {
  default = "1.21.1"
}