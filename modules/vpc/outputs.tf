output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_a_id" {
  description = "The ID of public subnet A"
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "The ID of public subnet B"
  value       = aws_subnet.public_subnet_b.id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public_route_table.id
}
