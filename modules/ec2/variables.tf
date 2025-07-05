variable "env" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "public_subnet_a_id" {
  type = string
}

variable "public_subnet_b_id" {
  type = string
}

variable "aws_security_group" {
  type = string
}

variable "ec2_role_name" {
  type = string
}
variable "kms_key_arn" {
  description = "KMS Key ARN for EBS encryption"
  type        = string
}
