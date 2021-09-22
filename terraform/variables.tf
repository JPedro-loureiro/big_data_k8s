variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "k8s_host"
}

variable "region" {
  description = "AWS Region"
  type = string
  default = "us-east-1"
}