variable "log_group_name" {
  type        = string
  description = "The name of cloudwatch log group on which the metric filters will apply, one of var.log_group_name or var.metrics_patterns.*.log_group_name is required"
  default     = null
}

variable "metrics_patterns" {
  type = list(object({
    name           = string
    pattern        = string
    unit           = optional(string, "None")
    dimensions     = optional(any, {})
    value          = optional(string, "1")
    default_value  = optional(string, "0")
    log_group_name = optional(string, null)
  }))
  default     = []
  description = "The configurations of log based metric filtration, one of var.log_group_name or var.metrics_patterns.*.log_group_name is required"
}

variable "metrics_namespace" {
  type        = string
  default     = "LogBasedMetrics"
  description = "The namespace of cloudwatch metric"
}
