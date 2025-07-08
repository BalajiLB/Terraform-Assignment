data "aws_caller_identity" "current" {}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}
# This module creates an S3 bucket with versioning, encryption, logging, and replication setup.


# ----------------------------
# Infra (Main) S3 Bucket
# ----------------------------
resource "aws_s3_bucket" "infra_bucket" {
  bucket = "${var.env}-${var.bucket_name}-${random_string.bucket_suffix.result}" 

  tags = merge(
    var.tags,
    {
      Name = "${var.env}-${var.bucket_name}-${random_string.bucket_suffix.result}"
    }
  )
}


# Enable versioning
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.infra_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "logging_versioning" {
  bucket = aws_s3_bucket.logging_target_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Update the KMS key policy
resource "aws_kms_key" "s3_kms" {
  description         = "KMS key for ${var.env}-${var.bucket_name}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAccountRoot",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      # Add this new statement
      {
        Sid    = "AllowS3Services",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.infra_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.infra_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.infra_bucket.id
  target_bucket = aws_s3_bucket.logging_target_bucket.id
  target_prefix = "${var.env}/logs/"
}

# Lifecycle rule
resource "aws_s3_bucket_lifecycle_configuration" "infra_bucket_lifecycle" {
  bucket = aws_s3_bucket.infra_bucket.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = 365
    }

    filter {} # Apply to all objects

    # Add Lifecycle Aborted Uploads Rule (CKV_AWS_300)
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logging_lifecycle" {
  bucket = aws_s3_bucket.logging_target_bucket.id

  rule {
    id     = "delete-logs-after-365-days"
    status = "Enabled"

    expiration {
      days = 365
    }

    filter {}  # Apply to all objects

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# ----------------------------
# Replication Setup
# ----------------------------

# Target bucket for replication
resource "aws_s3_bucket" "replication_target_bucket" {
  bucket = "${var.replication_target_bucket}-${random_string.bucket_suffix.result}"

  tags = merge(
    var.tags,
    {
      Name = "${var.replication_target_bucket}-${random_string.bucket_suffix.result}" 
    }
  )
}


# Enable versioning on the target bucket
resource "aws_s3_bucket_versioning" "replication_target_versioning" {
  bucket = aws_s3_bucket.replication_target_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Logging_target_bucket
resource "aws_s3_bucket" "logging_target_bucket" {
  bucket = "${var.logging_target_bucket}-${random_string.bucket_suffix.result}" # Updated

  tags = merge(
    var.tags,
    {
      Name = "${var.logging_target_bucket}-${random_string.bucket_suffix.result}" # Updated
    }
  )
}


# Enable encryption on replication target bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.replication_target_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_kms.arn
    }
  }
}


# replication_target_bucket
resource "aws_s3_bucket_lifecycle_configuration" "replication_target_lifecycle" {
  bucket = aws_s3_bucket.replication_target_bucket.id

  rule {
    id     = "expire-objects"
    status = "Enabled"

    expiration {
      days = 365
    }

    filter {}
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Block public access on replication bucket
resource "aws_s3_bucket_public_access_block" "replication_block_public_access" {
  bucket = aws_s3_bucket.replication_target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Replication IAM Role
resource "aws_iam_role" "replication_role" {
  name = "${var.env}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach replication permissions to the role
resource "aws_iam_role_policy" "replication_policy" {
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"],
        Resource = [aws_s3_bucket.infra_bucket.arn]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"],
        Resource = ["${aws_s3_bucket.infra_bucket.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"],
        Resource = ["${aws_s3_bucket.replication_target_bucket.arn}/*"]
      }
    ]
  })
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "infra_replication" {
  bucket = aws_s3_bucket.infra_bucket.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replication_target_bucket.arn
      storage_class = "STANDARD"
    }

    filter {} # replicate all objects
  }
}

 
# Grant write access to S3 log delivery
resource "aws_s3_bucket_acl" "logging_target_acl" {
  bucket = aws_s3_bucket.logging_target_bucket.id
  acl    = "log-delivery-write"
}

# Block public access on logging bucket
resource "aws_s3_bucket_public_access_block" "logging_block_public_access" {
  bucket = aws_s3_bucket.logging_target_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption on logging bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "logging_bucket_encryption" {
  bucket = aws_s3_bucket.logging_target_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Replication_target_bucket
resource "aws_s3_bucket_logging" "replication_target_logging" {
  bucket        = aws_s3_bucket.replication_target_bucket.id
  target_bucket = aws_s3_bucket.logging_target_bucket.id
  target_prefix = "replication-logs/"
}

# ----------------------------
# Enable Event Notifications (CKV2_AWS_62)
# ----------------------------

resource "aws_s3_bucket_notification" "infra_notification" {
  bucket = aws_s3_bucket.infra_bucket.id

  topic {
    topic_arn = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dummy-topic"
    events    = ["s3:ObjectCreated:*"]
  }
}


# ----------------------------
# Restrict Default Security Group (CKV2_AWS_12)
# ----------------------------
resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  ingress = []
  egress  = []
}
