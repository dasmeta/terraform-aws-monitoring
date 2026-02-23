variable "finding_publishing_frequency" {
  type        = string
  default     = "FIFTEEN_MINUTES"
  description = "Specifies the frequency of notifications sent for finding occurrences. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
}

variable "enable_s3_protection" {
  type        = bool
  default     = true
  description = "Enable S3 protection in GuardDuty"
}

variable "enable_kubernetes_protection" {
  type        = bool
  default     = true
  description = "Enable Kubernetes audit log protection in GuardDuty"
}

variable "enable_malware_protection" {
  type        = bool
  default     = true
  description = "Enable malware protection for EC2 instances in GuardDuty"
}

variable "filters" {
  type = map(object({
    description = optional(string)
    action      = string # Valid values: ARCHIVE, NOOP
    rank        = optional(number)
    finding_criteria = optional(object({
      criterion = optional(map(object({
        equals                = optional(list(string))
        not_equals            = optional(list(string))
        greater_than          = optional(number)
        greater_than_or_equal = optional(number)
        less_than             = optional(number)
        less_than_or_equal    = optional(number)
      })))
    }))
    tags = optional(map(string))
  }))
  default     = {}
  description = "Map of findings filters to create. Key is the filter name. If empty, no filters will be created."
}
