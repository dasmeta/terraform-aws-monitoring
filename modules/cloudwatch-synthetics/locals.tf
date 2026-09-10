locals {
  default_runtime = "syn-python-selenium-11.1"

  check_type_script_dirs = {
    soap_wsdl            = "soap_wsdl"
    soap_cardinfo        = "soap_cardinfo"
    rest_cardinfo        = "rest_cardinfo"
    blackhawk_management = "blackhawk_management"
  }

  default_secret_fields = {
    soap_wsdl            = {}
    soap_cardinfo        = { username = "username", password = "password", soap_action = "soap_action" }
    rest_cardinfo        = { api_key = "api_key", bearer_token = "token" }
    blackhawk_management = { client_id = "client_id", client_secret = "client_secret" }
  }

  canary_name_stems = {
    for key, cfg in var.canaries :
    key => replace(
      lower(replace("${var.name_prefix}-${key}", "_", "-")),
      "/[^a-z0-9-]/",
      ""
    )
  }

  canary_names = {
    for key, stem in local.canary_name_stems :
    key => length(stem) > 21 ? substr(stem, length(stem) - 21, 21) : stem
  }

  role_names = {
    for key, cfg in var.canaries :
    key => substr(replace("${var.name_prefix}-${key}-synthetics", "_", "-"), 0, 64)
  }

  alarm_names = {
    for key, cfg in var.canaries :
    key => substr(replace("${var.name_prefix}-${key}-canary-failed", "_", "-"), 0, 255)
  }

  artifact_bucket_id = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].id : var.artifact_bucket_name

  canary_configs = {
    for key, cfg in var.canaries : key => merge(cfg, {
      secret_fields = length(cfg.secret_fields) > 0 ? cfg.secret_fields : local.default_secret_fields[cfg.check_type]
      alarm_config = merge(
        {
          enabled             = true
          threshold           = 1
          evaluation_periods  = 1
          datapoints_to_alarm = 1
          period              = 60
          treat_missing_data  = "breaching"
          comparison_operator = "LessThanThreshold"
        },
        coalesce(cfg.alarm_config, {})
      )
    })
  }

  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
