# AWS Macie Module
# This module sets up Amazon Macie v2 which provides data security and data privacy
# Macie discovers, classifies, and protects sensitive data in AWS
# Findings are automatically sent to Security Hub

# Enable Amazon Macie v2
resource "aws_macie2_account" "this" {
  finding_publishing_frequency = var.finding_publishing_frequency
  status                       = var.status
}

# Macie Findings Filter (optional)
resource "aws_macie2_findings_filter" "this" {
  for_each = var.findings_filters

  name        = each.key
  description = try(each.value.description, null)
  action      = each.value.action
  position    = try(each.value.position, null)

  dynamic "finding_criteria" {
    for_each = each.value.finding_criteria != null ? [each.value.finding_criteria] : []
    content {
      dynamic "criterion" {
        for_each = finding_criteria.value.criterion != null ? finding_criteria.value.criterion : {}
        content {
          field = criterion.key
          eq    = try(criterion.value.eq, null)
          gt    = try(criterion.value.gt, null)
          gte   = try(criterion.value.gte, null)
          lt    = try(criterion.value.lt, null)
          lte   = try(criterion.value.lte, null)
          neq   = try(criterion.value.neq, null)
        }
      }
    }
  }

  tags = try(each.value.tags, null)

  depends_on = [
    aws_macie2_account.this
  ]
}
