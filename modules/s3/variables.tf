variable "env" {
  type        = string
  description = "Environment"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name"
}

variable "tags" {
  type        = map(string)
  description = "Common tags"
}
