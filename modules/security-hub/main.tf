# AWS Config Module - REQUIRED for Security Hub standards to work
# This module can be enabled independently of Security Hub, but is required for Security Hub standards to evaluate resources
module "config" {
  source = "../config"
  count  = var.config.enabled ? 1 : 0

  name                       = var.name
  create_service_linked_role = var.config.create_service_linked_role
  record_all_resources       = var.config.record_all_resources
  include_global_resources   = var.config.include_global_resources
  s3_bucket_name             = var.config.s3_bucket_name
  s3_bucket_force_destroy    = var.config.s3_bucket_force_destroy
  delivery_frequency         = var.config.delivery_frequency
  included_resource_types    = var.config.included_resource_types
  excluded_resource_types    = var.config.excluded_resource_types
  rules                      = var.config.rules
  tags                       = var.tags
}

# AWS Inspector Module - RECOMMENDED for EC2/EKS vulnerability scanning
# Inspector automatically scans resources across all regions in the account
# This module can be enabled independently of Security Hub, but findings are automatically sent to Security Hub when both are enabled
module "inspector" {
  source = "../inspector"
  count  = var.inspector.enabled ? 1 : 0

  resource_types = var.inspector.resource_types
  filters        = var.inspector.filters
}

# AWS GuardDuty Module - OPTIONAL threat detection service
# GuardDuty monitors for malicious activity and unauthorized behavior
# Findings are automatically sent to Security Hub when both are enabled
# This module can be enabled independently of Security Hub
module "guardduty" {
  source = "../guardduty"
  count  = var.guardduty.enabled ? 1 : 0

  finding_publishing_frequency = var.guardduty.finding_publishing_frequency
  enable_s3_protection         = var.guardduty.enable_s3_protection
  enable_kubernetes_protection = var.guardduty.enable_kubernetes_protection
  enable_malware_protection    = var.guardduty.enable_malware_protection
  filters                      = var.guardduty.filters
}

# Amazon Macie Module - OPTIONAL data security and privacy service
# Macie discovers, classifies, and protects sensitive data in S3
# Findings are automatically sent to Security Hub when both are enabled
# This module can be enabled independently of Security Hub
module "macie" {
  source = "../macie"
  count  = var.macie.enabled ? 1 : 0

  finding_publishing_frequency = var.macie.finding_publishing_frequency
  status                       = var.macie.status
  findings_filters             = var.macie.findings_filters
}

# CloudWatch Alarm Actions Module - OPTIONAL notifications for Security Hub findings
# This module manages SNS topics and subscriptions for sending findings to various channels
# Supports: email, SMS, Slack, Teams, ServiceNow, Jira, webhooks, Lambda functions
module "alarm_actions" {
  source = "../cloudwatch-alarm-actions"
  count  = var.alarm_actions.enabled ? 1 : 0

  topic_name   = local.sns_topic_name
  create_topic = var.alarm_actions.create_topic
  delivery_policy = var.alarm_actions.delivery_policy != null ? var.alarm_actions.delivery_policy : {
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  }
  policy                   = var.alarm_actions.policy
  email_addresses          = var.alarm_actions.email_addresses
  fallback_email_addresses = var.alarm_actions.fallback_email_addresses
  phone_numbers            = var.alarm_actions.phone_numbers
  fallback_phone_numbers   = var.alarm_actions.fallback_phone_numbers
  web_endpoints            = var.alarm_actions.web_endpoints
  fallback_web_endpoints   = var.alarm_actions.fallback_web_endpoints
  lambda_arns              = var.alarm_actions.lambda_arns
  fallback_lambda_arns     = var.alarm_actions.fallback_lambda_arns
  slack_webhooks           = var.alarm_actions.slack_webhooks
  servicenow_webhooks      = var.alarm_actions.servicenow_webhooks
  teams_webhooks           = var.alarm_actions.teams_webhooks
  jira_config              = var.alarm_actions.jira_config
  log_group_retention_days = var.alarm_actions.log_group_retention_days
  enable_dead_letter_queue = var.alarm_actions.enable_dead_letter_queue
  recreate_missing_package = var.alarm_actions.recreate_missing_package
  log_level                = var.alarm_actions.log_level
  lambda_failed_alert      = var.alarm_actions.lambda_failed_alert
}

# SNS topic policy to allow EventBridge to publish from both automated and manual alert rules
# IMPORTANT: aws_sns_topic_policy REPLACES the entire topic policy, so we must include all permissions:
# - Default owner permissions (when no custom policy provided)
# - Custom policy (when provided via var.alarm_actions.policy)
# - EventBridge publish permissions (always added)
resource "aws_sns_topic_policy" "eventbridge_publish" {
  count = var.alarm_actions.enabled && var.alarm_actions.topic_assign_security_hub_policy ? 1 : 0

  arn = module.alarm_actions[0].topic_arn
  # Use merged policy: default + EventBridge (when no custom policy) OR custom + EventBridge (when custom provided)
  # Don't pass policy to topic module - we'll set it via aws_sns_topic_policy to ensure EventBridge permissions are always included
  policy = var.alarm_actions.policy == null ? data.aws_iam_policy_document.sns_topic_policy_merged[0].json : data.aws_iam_policy_document.sns_topic_policy_custom_merged[0].json

  depends_on = [
    module.alarm_actions,
    aws_cloudwatch_event_rule.automated_alerts,
    aws_cloudwatch_event_rule.manual_alerts
  ]
}

resource "aws_securityhub_account" "sec-hub" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_action_target" "sec-hub-target" {
  name        = var.action_target_name
  identifier  = "SendToTargets"
  description = "This is custom action sends selected findings to Targets"

  depends_on = [
    aws_securityhub_account.sec-hub
  ]
}

resource "aws_securityhub_finding_aggregator" "sec-hub-aggregator" {
  linking_mode = var.link_mode

  count = var.enable_security_hub_finding_aggregator ? 1 : 0

  # When linking_mode is SPECIFIED_REGIONS, provide the list of regions
  specified_regions = var.link_mode == "SPECIFIED_REGIONS" ? var.specified_regions : null

  depends_on = [
    aws_securityhub_account.sec-hub
  ]
}

resource "aws_securityhub_member" "account" {
  for_each = var.securityhub_members

  account_id = each.value
  email      = each.key
  invite     = true
}

# Enable Security Hub standards
# IMPORTANT: AWS Config should be enabled (config.enabled = true) for standards to work properly.
# Without Config, Security Hub standards cannot evaluate resource configurations and won't detect
# misconfigurations in networking, IAM, and EC2/EKS resources.
#
# The for_each will be empty if Security Hub is disabled, so no standards will be created.
#
# Available standards (configure via enabled_standards variable):
# - aws-foundational-security-best-practices/v/1.0.0 (default)
# - cis-aws-foundations-benchmark/v/1.2.0 (default)
# - aws-resource-tagging-standard/v/1.0.0
# - cis-aws-foundations-benchmark/v/1.4.0
# - cis-aws-foundations-benchmark/v/3.0.0
# - cis-aws-foundations-benchmark/v/5.0.0
# - nist-800-171-rev2/v/1.0.0
# - nist-800-53-rev5/v/1.0.0
# - pci-dss/v/3.2.1
# - pci-dss/v/4.0.1
resource "aws_securityhub_standards_subscription" "standards" {
  for_each = local.enabled_standards_filtered

  standards_arn = each.value

  depends_on = [
    aws_securityhub_account.sec-hub,
    module.config
  ]
}
