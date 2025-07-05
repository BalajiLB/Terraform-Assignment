output "ec2_sg" {
  description = "Security Group ID for EC2"
  value       = aws_security_group.ec2_sg.id
}

output "ec2_sg" {
  value = aws_security_group.ec2_sg
}
