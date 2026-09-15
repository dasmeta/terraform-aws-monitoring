resource "aws_synthetics_canary" "this" {
  for_each = var.canaries

  name                 = local.canary_names[each.key]
  artifact_s3_location = "s3://${local.artifact_bucket_id}/canaries/${local.canary_names[each.key]}/"
  execution_role_arn   = aws_iam_role.canary[each.key].arn
  handler              = local.synthetics_handler
  runtime_version      = local.synthetics_runtime_version
  start_canary         = true
  delete_lambda        = true

  s3_bucket  = local.artifact_bucket_id
  s3_key     = aws_s3_object.canary_bundle[each.key].key
  s3_version = aws_s3_object.canary_bundle[each.key].version_id

  schedule {
    expression = each.value.schedule
  }

  run_config {
    timeout_in_seconds = each.value.timeout_seconds
    memory_in_mb       = each.value.memory_in_mb
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
    Name = local.canary_names[each.key]
  })

  depends_on = [aws_iam_role_policy.canary, aws_s3_object.canary_bundle]
}
