locals {
  # SNS topic name for alarm_actions module
  sns_topic_name                        = var.alarm_actions.topic_name != "" ? var.alarm_actions.topic_name : "${var.name}-security-hub-findings"
  finding_delivery_enabled              = var.alarm_actions.enabled && nonsensitive(var.finding_delivery.enabled)
  finding_cutover_at                    = local.finding_delivery_enabled ? (var.finding_delivery.cutover_at != null ? var.finding_delivery.cutover_at : aws_ssm_parameter.finding_cutover[0].value) : null
  delivery_failure_escalation_topic_arn = local.finding_delivery_enabled ? module.security_failure_actions[0].topic_arn : try(var.delivery_failure.escalation_topic_arn, null)

  # Security Hub Standards ARN mapping
  # Maps standard identifiers to their full ARNs
  security_hub_standards = {
    "aws-foundational-security-best-practices/v/1.0.0" = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
    "cis-aws-foundations-benchmark/v/1.2.0"            = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
    "aws-resource-tagging-standard/v/1.0.0"            = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-resource-tagging-standard/v/1.0.0"
    "cis-aws-foundations-benchmark/v/1.4.0"            = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/1.4.0"
    "cis-aws-foundations-benchmark/v/3.0.0"            = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/3.0.0"
    "cis-aws-foundations-benchmark/v/5.0.0"            = "arn:aws:securityhub:${data.aws_region.current.name}::standards/cis-aws-foundations-benchmark/v/5.0.0"
    "nist-800-171-rev2/v/1.0.0"                        = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-171-rev2/v/1.0.0"
    "nist-800-53-rev5/v/1.0.0"                         = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53-rev5/v/1.0.0"
    "pci-dss/v/3.2.1"                                  = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
    "pci-dss/v/4.0.1"                                  = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/4.0.1"
  }

  # Filter enabled standards to only those that exist in the mapping
  enabled_standards_filtered = {
    for standard in var.enabled_standards : standard => local.security_hub_standards[standard]
    if contains(keys(local.security_hub_standards), standard)
  }
}
