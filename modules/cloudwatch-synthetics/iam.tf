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
      [
        {
          Effect   = "Allow"
          Action   = "secretsmanager:GetSecretValue"
          Resource = each.value.secret_arn
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetBucketLocation", "s3:ListBucket"]
          Resource = local.artifact_bucket_arn
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject", "s3:GetObjectVersion"]
          Resource = "${local.artifact_bucket_arn}/${local.script_object_keys[each.key]}"
        },
        {
          Effect   = "Allow"
          Action   = ["s3:AbortMultipartUpload", "s3:PutObject"]
          Resource = "${local.artifact_bucket_arn}/canaries/${each.key}/*"
        },
        {
          Effect   = "Allow"
          Action   = "logs:CreateLogGroup"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
          Resource = "arn:${data.aws_partition.current.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/cwsyn-*:*"
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
      var.kms_key_arn != null ? [{
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = var.kms_key_arn
      }] : []
    )
  })
}
