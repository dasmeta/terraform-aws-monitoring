output "account_id" {
  description = "The ID of the Macie account"
  value       = aws_macie2_account.this.id
}

output "account_created_at" {
  description = "The date and time, in UTC and extended RFC 3339 format, when the Amazon Macie account was created"
  value       = aws_macie2_account.this.created_at
}

output "account_service_role" {
  description = "The Amazon Resource Name (ARN) of the service-linked role that allows Macie to monitor and analyze data in AWS resources for the account"
  value       = aws_macie2_account.this.service_role
}

output "filters" {
  description = "Map of Macie findings filter resources (key is filter name)"
  value       = aws_macie2_findings_filter.this
}
