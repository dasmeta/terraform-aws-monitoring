variable "resource_types" {
  type        = list(string)
  default     = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
  description = "Resource types to enable Inspector for. Valid values: EC2, ECR, LAMBDA, LAMBDA_CODE, CODE_REPOSITORY. LAMBDA scans Lambda function configuration (runtime, permissions). LAMBDA_CODE scans Lambda function code (dependencies, vulnerabilities). Both LAMBDA and LAMBDA_CODE are recommended for comprehensive Lambda scanning."
}

variable "filters" {
  type = map(object({
    description   = optional(string)
    filter_action = string # Valid values: ARCHIVE, NOOP
    filter_criteria = optional(object({
      aws_account_id = optional(object({
        comparison = string
        value      = string
      }))
      component_id = optional(object({
        comparison = string
        value      = string
      }))
      component_type = optional(object({
        comparison = string
        value      = string
      }))
      ec2_instance_image_id = optional(object({
        comparison = string
        value      = string
      }))
      ec2_instance_subnet_id = optional(object({
        comparison = string
        value      = string
      }))
      ec2_instance_vpc_id = optional(object({
        comparison = string
        value      = string
      }))
      ecr_image_pushed_at = optional(object({
        end_inclusive   = optional(string)
        start_inclusive = optional(string)
      }))
      ecr_image_tags = optional(object({
        comparison = string
        value      = string
      }))
      ecr_image_hash = optional(object({
        comparison = string
        value      = string
      }))
      finding_arn = optional(object({
        comparison = string
        value      = string
      }))
      finding_status = optional(object({
        comparison = string
        value      = string
      }))
      finding_type = optional(object({
        comparison = string
        value      = string
      }))
      first_observed_at = optional(object({
        end_inclusive   = optional(string)
        start_inclusive = optional(string)
      }))
      inspector_score = optional(object({
        lower_inclusive = optional(number)
        upper_inclusive = optional(number)
      }))
      last_observed_at = optional(object({
        end_inclusive   = optional(string)
        start_inclusive = optional(string)
      }))
      network_protocol = optional(object({
        comparison = string
        value      = string
      }))
      port_range = optional(object({
        begin_inclusive = optional(number)
        end_inclusive   = optional(number)
      }))
      related_vulnerabilities = optional(object({
        comparison = string
        value      = string
      }))
      resource_id = optional(object({
        comparison = string
        value      = string
      }))
      resource_tags = optional(object({
        comparison = string
        key        = string
        value      = optional(string)
      }))
      resource_type = optional(object({
        comparison = string
        value      = string
      }))
      severity = optional(object({
        comparison = string
        value      = string
      }))
      title = optional(object({
        comparison = string
        value      = string
      }))
      updated_at = optional(object({
        end_inclusive   = optional(string)
        start_inclusive = optional(string)
      }))
      vendor_severity = optional(object({
        comparison = string
        value      = string
      }))
      vulnerability_id = optional(object({
        comparison = string
        value      = string
      }))
      vulnerability_source = optional(object({
        comparison = string
        value      = string
      }))
    }))
  }))
  default     = {}
  description = "Map of findings filters to create. Key is the filter name. If empty, no filters will be created."
}
