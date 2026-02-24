output "resource_types" {
  description = "Resource types enabled for Inspector"
  value       = var.resource_types
}

output "filters" {
  description = "Map of Inspector filter resources (key is filter name)"
  value       = aws_inspector2_filter.this
}
