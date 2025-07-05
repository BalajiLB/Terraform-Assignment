# Environment and Region
variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
}

variable "availability_zone_a" {
  description = "Availability zone for public subnet A"
  type        = string
}

variable "availability_zone_b" {
  description = "Availability zone for public subnet B"
  type        = string
}

variable "default_route_cidr" {
  description = "Default route CIDR (usually 0.0.0.0/0)"
  type        = string
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# S3 Variables
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

# Security Group - Split Ingress Variables
variable "ingress_descriptions" {
  type        = list(string)
  description = "Descriptions for each ingress rule"
}

variable "ingress_from_ports" {
  type        = list(number)
  description = "From ports for each ingress rule"
}

variable "ingress_to_ports" {
  type        = list(number)
  description = "To ports for each ingress rule"
}

variable "ingress_cidr_blocks" {
  type        = list(list(string))
  description = "CIDR blocks for each ingress rule"
}

# Security Group - Egress Variables
variable "egress_from_port" {
  type        = number
  description = "Egress from port"
}

variable "egress_to_port" {
  type        = number
  description = "Egress to port"
}

variable "egress_protocol" {
  type        = string
  description = "Egress protocol"
}

variable "egress_cidr_blocks" {
  type        = list(string)
  description = "Egress CIDR blocks"
}

# Common Tags
variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
}

variable "ec2_role_name" {
  description = "IAM Role name to attach to EC2 instance profile"
  type        = string
}
