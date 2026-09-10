# Contract: Module Inputs

**Module**: `modules/cloudwatch-synthetics`  
**Consumer**: Terraform modules / root stacks referencing `dasmeta/monitoring/aws//modules/cloudwatch-synthetics`

## Required module variables

```hcl
variable "name_prefix" {
  type        = string
  description = "Prefix for generated resource names."
}

variable "sns_topic_arn" {
  type        = string
  description = "Consumer-owned SNS topic ARN for canary failure alarms."
}

variable "canaries" {
  type = map(object({
    check_type   = string
    endpoint_url = string
    secret_arn   = string

    schedule         = optional(string, "rate(1 minute)")
    timeout_seconds  = optional(number, 60)
    retries          = optional(number, 0)
    runtime_version  = optional(string, "syn-python-selenium-11.0")
    secret_fields    = optional(map(string), {})
    environment      = optional(map(string), {})
    tags             = optional(map(string), {})

    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))

    alarm_config = optional(object({
      enabled               = optional(bool, true)
      threshold             = optional(number, 1)
      evaluation_periods    = optional(number, 1)
      datapoints_to_alarm   = optional(number, 1)
      period                = optional(number, 60)
      treat_missing_data    = optional(string, "breaching")
      comparison_operator   = optional(string, "LessThanThreshold")
    }))
  }))
  description = "Map of canary configurations keyed by stable logical name."
}
```

## Optional module variables

```hcl
variable "create_artifact_bucket" {
  type    = bool
  default = true
}

variable "artifact_bucket_name" {
  type    = string
  default = null
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "artifact_expiration_days" {
  type    = number
  default = 30
}

variable "default_tags" {
  type    = map(string)
  default = {}
}
```

## Outputs

```hcl
output "canary_arns" {
  description = "Map of canary key to Synthetics canary ARN."
  value       = { for k, v in aws_synthetics_canary.this : k => v.arn }
}

output "canary_names" {
  description = "Map of canary key to canary name."
  value       = { for k, v in aws_synthetics_canary.this : k => v.name }
}

output "alarm_arns" {
  description = "Map of canary key to CloudWatch alarm ARN."
}

output "artifact_bucket_arn" {
  description = "ARN of module-managed artifact bucket."
}

output "execution_role_arns" {
  description = "Map of canary key to IAM execution role ARN."
}
```

## Validation contract

Plan MUST fail when:

1. Any `check_type` is outside the allowed set.
2. Any ARN variable is malformed.
3. `timeout_seconds` is outside 3–840.
4. `vpc_config` is partially specified.
5. `create_artifact_bucket = false` without `artifact_bucket_name`.
6. `canaries` is empty.

## Backward compatibility

Initial release — no prior interface. Future changes require semver minor/major per Terraform module conventions and Speckit gate for breaking input changes.
