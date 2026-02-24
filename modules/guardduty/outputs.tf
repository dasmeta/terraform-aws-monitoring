output "detector_id" {
  description = "The ID of the GuardDuty detector"
  value       = aws_guardduty_detector.this.id
}

output "filters" {
  description = "Map of GuardDuty filter resources (key is filter name)"
  value       = aws_guardduty_filter.this
}
