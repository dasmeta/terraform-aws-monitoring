resource "aws_s3_bucket" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket        = coalesce(var.artifact_bucket_name, "${var.name_prefix}-synthetics-artifacts-${local.account_id}")
  force_destroy = false

  tags = merge(var.default_tags, {
    Name = "${var.name_prefix}-synthetics-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-canary-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = var.artifact_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.artifacts]
}
