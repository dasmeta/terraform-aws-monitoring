resource "aws_iam_role" "canary" {
  for_each = var.canaries

  name = local.role_names[each.key]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["lambda.amazonaws.com", "synthetics.amazonaws.com"]
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.default_tags, each.value.tags, {
    Name = local.role_names[each.key]
  })
}

resource "aws_iam_role_policy" "canary" {
  for_each = var.canaries

  name = "${local.role_names[each.key]}-policy"
  role = aws_iam_role.canary[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      contains(keys(data.aws_secretsmanager_secret.canary), each.key) ? [{
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = data.aws_secretsmanager_secret.canary[each.key].arn
      }] : [],
      [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:PutObject", "s3:AbortMultipartUpload"]
          Resource = "${local.artifact_bucket_arn}/canaries/${local.canary_names[each.key]}/*"
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:GetObjectVersion"]
          Resource = "${local.artifact_bucket_arn}/${local.script_object_keys[each.key]}"
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
          Resource = local.artifact_bucket_arn
        },
        {
          Effect   = "Allow"
          Action   = "s3:ListAllMyBuckets"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:${data.aws_partition.current.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/cwsyn-${local.canary_names[each.key]}-*"
        },
        {
          Effect   = "Allow"
          Action   = "cloudwatch:PutMetricData"
          Resource = "*"
          Condition = {
            StringEquals = {
              "cloudwatch:namespace" = "CloudWatchSynthetics"
            }
          }
        },
      ],
      contains(keys(data.aws_kms_key.secret_encryption), each.key) ? (
        data.aws_kms_key.secret_encryption[each.key].key_manager == "CUSTOMER" ? [{
          Effect   = "Allow"
          Action   = "kms:Decrypt"
          Resource = data.aws_kms_key.secret_encryption[each.key].arn
          Condition = {
            StringEquals = {
              "kms:ViaService"                  = "secretsmanager.${local.region}.amazonaws.com"
              "kms:EncryptionContext:SecretARN" = data.aws_secretsmanager_secret.canary[each.key].arn
            }
          }
        }] : []
      ) : [],
      var.kms_key_arn != null ? [{
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey*"]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${local.region}.amazonaws.com"
          }
        }
      }] : [],
      each.value.vpc_config != null ? [{
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
        ]
        Resource = "*"
      }] : []
    )
  })
}
