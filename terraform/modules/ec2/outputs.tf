output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.consumer.id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.consumer.public_ip
}

output "ec2_private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.consumer.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ${var.ec2_key_pair_name}.pem ec2-user@${aws_instance.consumer.public_ip}"
}
