terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "personal"
  region  = var.region
}

resource "aws_security_group" "k8s" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    }
  ]
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCi1ETT8BM54TuiJ7CB0GfcZNDQC5h6ALfF/QUp8GzC6FuXwTS9jOpc21Ug/VpMoerttvPLREPMKRfcBkRhQ1PFMvnlBHUjoWYosN5unhUciya/g4JmjLg9nTA/9rHqiH9br55PXH37vyEoFUE64xOA56w9QalWkvhlcz6+M72A8T3G/JKwz9B7+H9R9avKWPtY12iWfrAe+u/HTDaIHfdIoD1xGN4UeLbJ3RLmE7KYSxvleTl+RtB+1hbzO9kGZz8o8uQJXSVS/CSVPK3bBsJVcIfzVIP0kmVZJ4VLjmmCWsqViQXwcgDyhXEs79VmKRWb4lgSeN/dZb1hk0Cr7Xzr75BeAnaIEFv+9cXP5OUNe+2BL1hFq0sgIoHdQdJIN8ARncqzwKypE5Mb+56gPDA9EZ/HuD9N+oqDvevpXJmnqOWvpEAPTP/JBj7Vidy0ln6XsCn1/yZcsuvlr4nZ85HmlsDAXTa7FXlWOn4tapSj+B9WIBfd870SURStQk17SP0= joao-loureiro@BLU028698"
}

resource "aws_instance" "k8s_host" {
  ami                     = "ami-09e67e426f25ce0d7"
  instance_type           = "t3a.large"
  key_name                = "k8s_key"
  vpc_security_group_ids = [aws_security_group.k8s.id]
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/home/joao-loureiro/.ssh/id_rsa")
  }
  root_block_device {
    volume_size = 50
    tags = {
      Name = "k8s_volume"
      "usecase" = "k8s"
    }
  }
  tags = {
    Name = var.instance_name
    "usecase" = "k8s"
  }
}
