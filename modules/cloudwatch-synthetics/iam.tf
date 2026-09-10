resource "aws_iam_role" "canary" {
  for_each = var.canaries

  name = local.role_names[each.key]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "synthetics.amazonaws.com",
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
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
          Effect = "Allow"
          Action = [
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket",
          ]
          Resource = [
            "arn:aws:s3:::${local.artifact_bucket_id}",
            "arn:aws:s3:::${local.artifact_bucket_id}/canaries/${each.key}/*",
            "arn:aws:s3:::${local.artifact_bucket_id}/scripts/${each.key}/*",
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Resource = [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/cwsyn-*",
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/synthetics/${local.canary_names[each.key]}",
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/synthetics/${local.canary_names[each.key]}:*",
          ]
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
      var.kms_key_arn != null ? [
        {
          Effect   = "Allow"
          Action   = "kms:Decrypt"
          Resource = var.kms_key_arn
        }
      ] : []
    )
  })
}
