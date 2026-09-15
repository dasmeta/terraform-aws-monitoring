locals {
  # SNS topic name for alarm_actions module
  sns_topic_name = var.alarm_actions.topic_name != "" ? var.alarm_actions.topic_name : "${var.name}-security-hub-findings"

  # Security Hub Standards ARN mapping
  # Maps standard identifiers to their full ARNs
  security_hub_standards = {
    "aws-foundational-security-best-practices/v/1.0.0" = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
    "cis-aws-foundations-benchmark/v/1.2.0"            = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
    "aws-resource-tagging-standard/v/1.0.0"            = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-resource-tagging-standard/v/1.0.0"
    "cis-aws-foundations-benchmark/v/1.4.0"            = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"
    "cis-aws-foundations-benchmark/v/3.0.0"            = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/3.0.0"
    "cis-aws-foundations-benchmark/v/5.0.0"            = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/5.0.0"
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

  service_alert_event_patterns = {
    guardduty = {
      source        = ["aws.guardduty"]
      "detail-type" = ["GuardDuty Finding"]
      detail = {
        severity = [{ numeric = [">=", 4] }]
        service = {
          archived = [false]
        }
      }
    }
    inspector = {
      source        = ["aws.inspector2"]
      "detail-type" = ["Inspector2 Finding"]
      detail = {
        severity = ["CRITICAL", "HIGH"]
        status   = ["ACTIVE"]
      }
    }
    macie = {
      source        = ["aws.macie"]
      "detail-type" = ["Macie Finding"]
      detail = {
        archived = [false]
        severity = {
          description = ["High"]
        }
      }
    }
  }

  enabled_service_alert_event_patterns = {
    for service, enabled in {
      guardduty = var.automated_alerts.guardduty
      inspector = var.automated_alerts.inspector
      macie     = var.automated_alerts.macie
    } : service => local.service_alert_event_patterns[service] if enabled
  }
}
