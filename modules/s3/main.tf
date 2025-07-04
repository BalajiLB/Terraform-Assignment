resource "aws_s3_bucket" "infra_bucket" {
  bucket = "${var.env}-${var.bucket_name}"

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.bucket_name}"
    }
  )
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.infra_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Add server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.infra_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
