# AWS GuardDuty Module
# This module sets up AWS GuardDuty which provides threat detection
# GuardDuty monitors for malicious activity and unauthorized behavior
# Findings are automatically sent to Security Hub

data "aws_region" "current" {}

# Enable AWS GuardDuty
resource "aws_guardduty_detector" "this" {
  enable                       = true
  finding_publishing_frequency = var.finding_publishing_frequency
  datasources {
    s3_logs {
      enable = var.enable_s3_protection
    }
    kubernetes {
      audit_logs {
        enable = var.enable_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.enable_malware_protection
        }
      }
    }
  }
}

# GuardDuty Findings Filter (optional)
resource "aws_guardduty_filter" "this" {
  for_each = var.filters

  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  description = try(each.value.description, null)
  action      = each.value.action
  rank        = try(each.value.rank, null)

  dynamic "finding_criteria" {
    for_each = each.value.finding_criteria != null ? [each.value.finding_criteria] : []
    content {
      dynamic "criterion" {
        for_each = finding_criteria.value.criterion != null ? finding_criteria.value.criterion : {}
        content {
          field                 = criterion.key
          equals                = try(criterion.value.equals, null)
          not_equals            = try(criterion.value.not_equals, null)
          greater_than          = try(criterion.value.greater_than, null)
          greater_than_or_equal = try(criterion.value.greater_than_or_equal, null)
          less_than             = try(criterion.value.less_than, null)
          less_than_or_equal    = try(criterion.value.less_than_or_equal, null)
        }
      }
    }
  }

  tags = try(each.value.tags, null)

  depends_on = [
    aws_guardduty_detector.this
  ]
}
