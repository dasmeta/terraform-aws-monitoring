locals {
  sanitized_name_prefix      = trim(replace(lower(var.name_prefix), "/[^a-z0-9-]/", ""), "-")
  synthetics_runtime_version = "syn-python-selenium-11.1"
  synthetics_handler         = "canary.handler"

  archive_output_paths = {
    for key, cfg in var.canaries :
    key => "${path.root}/.terraform/cloudwatch-synthetics-${substr(sha1("${path.root}:${var.name_prefix}:${key}"), 0, 16)}.zip"
  }

  canary_name_stems = {
    for key, cfg in var.canaries :
    key => trim(replace(lower("${local.sanitized_name_prefix}-${key}"), "/[^a-z0-9-]/", ""), "-")
  }

  canary_names = {
    for key, stem in local.canary_name_stems :
    key => "${substr(stem, 0, 13)}-${substr(sha1("${var.name_prefix}:${key}"), 0, 7)}"
  }

  role_names = {
    for key, cfg in var.canaries :
    key => "${substr(local.canary_name_stems[key], 0, 55)}-${substr(sha1("${var.name_prefix}:${key}:role"), 0, 8)}"
  }

  alarm_names = {
    for key, cfg in var.canaries :
    key => "${local.canary_names[key]}-failed"
  }

  artifact_bucket_suffix         = "synthetics-${local.region}-${local.account_id}"
  generated_artifact_bucket_name = "${substr(local.sanitized_name_prefix, 0, 63 - length(local.artifact_bucket_suffix) - 1)}-${local.artifact_bucket_suffix}"
  artifact_bucket_id             = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].id : var.artifact_bucket_name
  artifact_bucket_arn            = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].arn : "arn:${data.aws_partition.current.partition}:s3:::${var.artifact_bucket_name}"

  script_object_keys = {
    for key, cfg in var.canaries :
    key => "scripts/${substr(sha1("${var.name_prefix}:${key}"), 0, 16)}/bundle.zip"
  }

  canaries_with_secrets = {
    for key, cfg in var.canaries : key => cfg
    if cfg.secret_name != null && trimspace(cfg.secret_name) != ""
  }

  canary_configs = {
    for key, cfg in var.canaries : key => merge(cfg, {
      config = contains(keys(local.canaries_with_secrets), key) ? merge(cfg.config, {
        secret_name = cfg.secret_name
      }) : cfg.config
    })
  }

  account_id = data.aws_caller_identity.current.account_id
  # name remains required for AWS provider 5.x; .region exists only in 6.x.
  region = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
