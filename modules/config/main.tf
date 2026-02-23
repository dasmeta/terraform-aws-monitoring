# AWS Config Module
# This module sets up AWS Config which is REQUIRED for Security Hub to work properly
# Security Hub standards rely on AWS Config to evaluate resource configurations

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# AWS Config uses a service-linked role instead of a custom IAM role
# This is required to pass Security Hub's Config.1 control (CIS AWS Foundations Benchmark)
# Role ARN format: arn:aws:iam::ACCOUNT_ID:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig
#
# Behavior:
# - If var.create_service_linked_role = true (default): Creates the role. Will fail with EntityAlreadyExists if role exists.
# - If var.create_service_linked_role = false: Uses existing role via data source. Will fail if role doesn't exist.
#
# If you get EntityAlreadyExists error, set create_service_linked_role = false and import:
# terraform import module.config.aws_iam_service_linked_role.config aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig

# Get the existing service-linked role (used when create_service_linked_role = false)
data "aws_iam_role" "config_service_linked_role" {
  count = var.create_service_linked_role ? 0 : 1
  name  = "aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
}

# Create the service-linked role (used when create_service_linked_role = true)
resource "aws_iam_service_linked_role" "config" {
  count            = var.create_service_linked_role ? 1 : 0
  aws_service_name = "config.amazonaws.com"
  description      = "Service-linked role for AWS Config to access resources in your account"
}

# Get the role ARN from either the created resource or the existing data source
locals {
  config_service_linked_role_arn = var.create_service_linked_role ? aws_iam_service_linked_role.config[0].arn : data.aws_iam_role.config_service_linked_role[0].arn
}

# AWS Config Configuration Recorder
# Uses the AWS Config service-linked role to comply with Security Hub standards
resource "aws_config_configuration_recorder" "this" {
  name     = var.name
  role_arn = local.config_service_linked_role_arn

  depends_on = [
    aws_iam_service_linked_role.config,
    data.aws_iam_role.config_service_linked_role
  ]

  recording_group {
    all_supported                 = var.record_all_resources && length(var.included_resource_types) == 0
    include_global_resource_types = var.include_global_resources

    # If specific resource types are excluded, use exclusion-based recording
    dynamic "exclusion_by_resource_types" {
      for_each = var.record_all_resources && length(var.excluded_resource_types) > 0 ? [1] : []
      content {
        resource_types = var.excluded_resource_types
      }
    }

    # If specific resource types are provided, use inclusion-based recording
    dynamic "recording_strategy" {
      for_each = !var.record_all_resources && length(var.included_resource_types) > 0 ? [1] : []
      content {
        use_only = "INCLUSION_BY_RESOURCE_TYPES"
      }
    }

    # Resource types list for inclusion-based recording
    resource_types = !var.record_all_resources && length(var.included_resource_types) > 0 ? var.included_resource_types : null
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "this" {
  name           = var.name
  s3_bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : aws_s3_bucket.config[0].bucket

  dynamic "snapshot_delivery_properties" {
    for_each = var.delivery_frequency != null ? [1] : []
    content {
      delivery_frequency = var.delivery_frequency
    }
  }

  depends_on = [
    aws_config_configuration_recorder.this,
    aws_s3_bucket.config,
    aws_s3_bucket_policy.config
  ]
}

# S3 Bucket for Config (if not provided)
resource "aws_s3_bucket" "config" {
  count = var.s3_bucket_name == "" ? 1 : 0

  bucket        = "${var.name}-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count = var.s3_bucket_name == "" ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count = var.s3_bucket_name == "" ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Policy for Config to write to the bucket
# This policy is required for AWS Config to deliver configuration snapshots to S3
resource "aws_s3_bucket_policy" "config" {
  count = var.s3_bucket_name == "" ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.config,
    aws_s3_bucket_server_side_encryption_configuration.config,
    aws_s3_bucket_public_access_block.config
  ]
}

# Start Config Recorder
resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.this
  ]
}

# AWS Config Rules (optional)
resource "aws_config_config_rule" "this" {
  for_each = var.rules

  name        = each.key
  description = try(each.value.description, null)

  dynamic "source" {
    for_each = each.value.source != null ? [each.value.source] : []
    content {
      owner             = source.value.owner
      source_identifier = source.value.source_identifier

      dynamic "source_detail" {
        for_each = source.value.source_detail != null ? source.value.source_detail : []
        content {
          event_source                = try(source_detail.value.event_source, null)
          maximum_execution_frequency = try(source_detail.value.maximum_execution_frequency, null)
          message_type                = try(source_detail.value.message_type, null)
        }
      }
    }
  }

  dynamic "scope" {
    for_each = each.value.scope != null ? [each.value.scope] : []
    content {
      compliance_resource_types = try(scope.value.compliance_resource_types, null)
      compliance_resource_id    = try(scope.value.compliance_resource_id, null)
      tag_key                   = try(scope.value.tag_key, null)
      tag_value                 = try(scope.value.tag_value, null)
    }
  }

  input_parameters = try(each.value.input_parameters, null)
  tags             = try(each.value.tags, null)

  depends_on = [
    aws_config_configuration_recorder.this
  ]
}
