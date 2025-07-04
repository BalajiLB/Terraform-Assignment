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
