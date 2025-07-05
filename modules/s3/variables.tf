variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "bucket_name" {
  type        = string
  description = "Name of the main S3 bucket (without environment prefix)"
}

variable "replication_target_bucket" {
  type        = string
  description = "The name of the destination bucket for cross-region replication"
}

variable "logging_target_bucket" {
  type        = string
  description = "The S3 bucket where access logs will be delivered"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resources"
}

variable "vpc_id" {
  description = "VPC ID for default security group"
  type        = string
}
