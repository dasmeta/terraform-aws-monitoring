# AWS Inspector v2 Module
# This module sets up AWS Inspector v2 which is RECOMMENDED for EC2/EKS/Lambda vulnerability scanning
# Inspector scans EC2 instances, container images, and Lambda functions for vulnerabilities
# When enabled, Inspector automatically scans resources across ALL regions in the account
# Findings are automatically sent to Security Hub

data "aws_caller_identity" "current" {}

# Enable Amazon Inspector v2
resource "aws_inspector2_enabler" "this" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = var.resource_types
}

# Inspector Findings Filter (optional)
resource "aws_inspector2_filter" "this" {
  for_each = var.filters

  name        = each.key
  description = try(each.value.description, null)
  action      = each.value.filter_action

  dynamic "filter_criteria" {
    for_each = each.value.filter_criteria != null ? [each.value.filter_criteria] : []
    content {
      dynamic "aws_account_id" {
        for_each = filter_criteria.value.aws_account_id != null ? [filter_criteria.value.aws_account_id] : []
        content {
          comparison = aws_account_id.value.comparison
          value      = aws_account_id.value.value
        }
      }
      dynamic "component_id" {
        for_each = filter_criteria.value.component_id != null ? [filter_criteria.value.component_id] : []
        content {
          comparison = component_id.value.comparison
          value      = component_id.value.value
        }
      }
      dynamic "component_type" {
        for_each = filter_criteria.value.component_type != null ? [filter_criteria.value.component_type] : []
        content {
          comparison = component_type.value.comparison
          value      = component_type.value.value
        }
      }
      dynamic "ec2_instance_image_id" {
        for_each = filter_criteria.value.ec2_instance_image_id != null ? [filter_criteria.value.ec2_instance_image_id] : []
        content {
          comparison = ec2_instance_image_id.value.comparison
          value      = ec2_instance_image_id.value.value
        }
      }
      dynamic "ec2_instance_subnet_id" {
        for_each = filter_criteria.value.ec2_instance_subnet_id != null ? [filter_criteria.value.ec2_instance_subnet_id] : []
        content {
          comparison = ec2_instance_subnet_id.value.comparison
          value      = ec2_instance_subnet_id.value.value
        }
      }
      dynamic "ec2_instance_vpc_id" {
        for_each = filter_criteria.value.ec2_instance_vpc_id != null ? [filter_criteria.value.ec2_instance_vpc_id] : []
        content {
          comparison = ec2_instance_vpc_id.value.comparison
          value      = ec2_instance_vpc_id.value.value
        }
      }
      dynamic "ecr_image_pushed_at" {
        for_each = filter_criteria.value.ecr_image_pushed_at != null ? [filter_criteria.value.ecr_image_pushed_at] : []
        content {
          end_inclusive   = try(ecr_image_pushed_at.value.end_inclusive, null)
          start_inclusive = try(ecr_image_pushed_at.value.start_inclusive, null)
        }
      }
      dynamic "ecr_image_tags" {
        for_each = filter_criteria.value.ecr_image_tags != null ? [filter_criteria.value.ecr_image_tags] : []
        content {
          comparison = ecr_image_tags.value.comparison
          value      = ecr_image_tags.value.value
        }
      }
      dynamic "ecr_image_hash" {
        for_each = filter_criteria.value.ecr_image_hash != null ? [filter_criteria.value.ecr_image_hash] : []
        content {
          comparison = ecr_image_hash.value.comparison
          value      = ecr_image_hash.value.value
        }
      }
      dynamic "finding_arn" {
        for_each = filter_criteria.value.finding_arn != null ? [filter_criteria.value.finding_arn] : []
        content {
          comparison = finding_arn.value.comparison
          value      = finding_arn.value.value
        }
      }
      dynamic "finding_status" {
        for_each = filter_criteria.value.finding_status != null ? [filter_criteria.value.finding_status] : []
        content {
          comparison = finding_status.value.comparison
          value      = finding_status.value.value
        }
      }
      dynamic "finding_type" {
        for_each = filter_criteria.value.finding_type != null ? [filter_criteria.value.finding_type] : []
        content {
          comparison = finding_type.value.comparison
          value      = finding_type.value.value
        }
      }
      dynamic "first_observed_at" {
        for_each = filter_criteria.value.first_observed_at != null ? [filter_criteria.value.first_observed_at] : []
        content {
          end_inclusive   = try(first_observed_at.value.end_inclusive, null)
          start_inclusive = try(first_observed_at.value.start_inclusive, null)
        }
      }
      dynamic "inspector_score" {
        for_each = filter_criteria.value.inspector_score != null ? [filter_criteria.value.inspector_score] : []
        content {
          lower_inclusive = try(inspector_score.value.lower_inclusive, null)
          upper_inclusive = try(inspector_score.value.upper_inclusive, null)
        }
      }
      dynamic "last_observed_at" {
        for_each = filter_criteria.value.last_observed_at != null ? [filter_criteria.value.last_observed_at] : []
        content {
          end_inclusive   = try(last_observed_at.value.end_inclusive, null)
          start_inclusive = try(last_observed_at.value.start_inclusive, null)
        }
      }
      dynamic "network_protocol" {
        for_each = filter_criteria.value.network_protocol != null ? [filter_criteria.value.network_protocol] : []
        content {
          comparison = network_protocol.value.comparison
          value      = network_protocol.value.value
        }
      }
      dynamic "port_range" {
        for_each = filter_criteria.value.port_range != null ? [filter_criteria.value.port_range] : []
        content {
          begin_inclusive = try(port_range.value.begin_inclusive, null)
          end_inclusive   = try(port_range.value.end_inclusive, null)
        }
      }
      dynamic "related_vulnerabilities" {
        for_each = filter_criteria.value.related_vulnerabilities != null ? [filter_criteria.value.related_vulnerabilities] : []
        content {
          comparison = related_vulnerabilities.value.comparison
          value      = related_vulnerabilities.value.value
        }
      }
      dynamic "resource_id" {
        for_each = filter_criteria.value.resource_id != null ? [filter_criteria.value.resource_id] : []
        content {
          comparison = resource_id.value.comparison
          value      = resource_id.value.value
        }
      }
      dynamic "resource_tags" {
        for_each = filter_criteria.value.resource_tags != null ? [filter_criteria.value.resource_tags] : []
        content {
          comparison = resource_tags.value.comparison
          key        = resource_tags.value.key
          value      = try(resource_tags.value.value, null)
        }
      }
      dynamic "resource_type" {
        for_each = filter_criteria.value.resource_type != null ? [filter_criteria.value.resource_type] : []
        content {
          comparison = resource_type.value.comparison
          value      = resource_type.value.value
        }
      }
      dynamic "severity" {
        for_each = filter_criteria.value.severity != null ? [filter_criteria.value.severity] : []
        content {
          comparison = severity.value.comparison
          value      = severity.value.value
        }
      }
      dynamic "title" {
        for_each = filter_criteria.value.title != null ? [filter_criteria.value.title] : []
        content {
          comparison = title.value.comparison
          value      = title.value.value
        }
      }
      dynamic "updated_at" {
        for_each = filter_criteria.value.updated_at != null ? [filter_criteria.value.updated_at] : []
        content {
          end_inclusive   = try(updated_at.value.end_inclusive, null)
          start_inclusive = try(updated_at.value.start_inclusive, null)
        }
      }
      dynamic "vendor_severity" {
        for_each = filter_criteria.value.vendor_severity != null ? [filter_criteria.value.vendor_severity] : []
        content {
          comparison = vendor_severity.value.comparison
          value      = vendor_severity.value.value
        }
      }
      dynamic "vulnerability_id" {
        for_each = filter_criteria.value.vulnerability_id != null ? [filter_criteria.value.vulnerability_id] : []
        content {
          comparison = vulnerability_id.value.comparison
          value      = vulnerability_id.value.value
        }
      }
      dynamic "vulnerability_source" {
        for_each = filter_criteria.value.vulnerability_source != null ? [filter_criteria.value.vulnerability_source] : []
        content {
          comparison = vulnerability_source.value.comparison
          value      = vulnerability_source.value.value
        }
      }
    }
  }

  depends_on = [
    aws_inspector2_enabler.this
  ]
}
