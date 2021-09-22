output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_host.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k8s_host.public_ip
}
