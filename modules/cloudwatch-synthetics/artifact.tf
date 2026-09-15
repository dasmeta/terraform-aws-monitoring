resource "aws_s3_object" "canary_bundle" {
  for_each = var.canaries

  bucket      = local.artifact_bucket_id
  key         = local.script_object_keys[each.key]
  source      = archive_file.canary_bundle[each.key].output_path
  source_hash = archive_file.canary_bundle[each.key].output_base64sha256

  tags = merge(var.default_tags, each.value.tags, {
    Name      = "${local.canary_names[each.key]}-script"
    CanaryKey = each.key
  })

  lifecycle {
    precondition {
      condition     = var.create_artifact_bucket || (var.artifact_bucket_name != null && trimspace(var.artifact_bucket_name) != "")
      error_message = "artifact_bucket_name is required when create_artifact_bucket is false."
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.artifacts,
    aws_s3_bucket_server_side_encryption_configuration.artifacts,
    aws_s3_bucket_public_access_block.artifacts,
    aws_s3_bucket_ownership_controls.artifacts,
    aws_s3_bucket_policy.artifacts,
  ]
}
