resource "aws_cloudwatch_log_group" "canary" {
  for_each = var.canaries

  name              = "/aws/synthetics/${local.canary_names[each.key]}"
  retention_in_days = var.log_retention_days

  tags = merge(var.default_tags, each.value.tags, {
    Name = local.canary_names[each.key]
  })
}

resource "aws_synthetics_canary" "this" {
  for_each = var.canaries

  name                 = local.canary_names[each.key]
  artifact_s3_location = "s3://${local.artifact_bucket_id}/canaries/${each.key}/"
  execution_role_arn   = aws_iam_role.canary[each.key].arn
  handler              = "canary.handler"
  runtime_version      = each.value.runtime_version
  start_canary         = true

  s3_bucket  = local.artifact_bucket_id
  s3_key     = aws_s3_object.canary_bundle[each.key].key
  s3_version = aws_s3_object.canary_bundle[each.key].version_id

  schedule {
    expression = each.value.schedule
  }

  run_config {
    timeout_in_seconds = each.value.timeout_seconds
    memory_in_mb       = 960
    active_tracing     = false
  }

  dynamic "vpc_config" {
    for_each = each.value.vpc_config != null ? [each.value.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  tags = merge(var.default_tags, each.value.tags, {
    Name      = local.canary_names[each.key]
    CheckType = each.value.check_type
  })

  depends_on = [
    aws_iam_role_policy.canary,
    aws_s3_object.canary_bundle,
    aws_cloudwatch_log_group.canary,
  ]
}
