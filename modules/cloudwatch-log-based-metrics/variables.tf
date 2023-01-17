variable "log_group_name" {
  type        = string
  description = "The name of cloudwatch log group on which the metric filters will apply"
}

variable "metrics_patterns" {
  type = list(object({
    name       = string
    pattern    = string
    unit       = optional(string, "None")
    dimensions = any
  }))
  default     = []
  description = "The configurations of log based metric filtration"
}

variable "metrics_namespace" {
  type        = string
  default     = "LogBasedMetrics"
  description = "The namespace of cloudwatch metric"
}
