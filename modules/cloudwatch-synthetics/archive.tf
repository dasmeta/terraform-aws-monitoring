data "archive_file" "canary_bundle" {
  for_each = var.canaries

  type        = "zip"
  output_path = "${path.module}/builds/${each.key}-${sha256(jsonencode(local.canary_configs[each.key]))}.zip"

  source {
    content  = file("${path.module}/src/${local.check_type_script_dirs[each.value.check_type]}/python/canary.py")
    filename = "python/canary.py"
  }

  source {
    content  = file("${path.module}/src/common/secret_config.py")
    filename = "python/secret_config.py"
  }

  source {
    content  = file("${path.module}/src/common/logging_utils.py")
    filename = "python/logging_utils.py"
  }

  source {
    content  = file("${path.module}/src/common/http_utils.py")
    filename = "python/http_utils.py"
  }

  source {
    content = jsonencode({
      endpoint_url  = each.value.endpoint_url
      secret_arn    = each.value.secret_arn
      secret_fields = local.canary_configs[each.key].secret_fields
      environment   = each.value.environment
      check_type    = each.value.check_type
      canary_name   = local.canary_names[each.key]
    })
    filename = "python/config.json"
  }
}

resource "aws_s3_object" "canary_bundle" {
  for_each = var.canaries

  bucket = var.create_artifact_bucket ? aws_s3_bucket_versioning.artifacts[0].bucket : local.artifact_bucket_id
  key    = "scripts/${each.key}/bundle.zip"
  source = data.archive_file.canary_bundle[each.key].output_path
  etag   = data.archive_file.canary_bundle[each.key].output_md5

  tags = merge(var.default_tags, each.value.tags, {
    Name      = "${local.canary_names[each.key]}-script"
    CheckType = each.value.check_type
    CanaryKey = each.key
  })

  depends_on = [
    aws_s3_bucket_versioning.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.artifacts,
    aws_s3_bucket_public_access_block.artifacts,
    aws_s3_bucket_ownership_controls.artifacts,
    aws_s3_bucket_policy.artifacts,
  ]
}
