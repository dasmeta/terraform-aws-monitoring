variable "finding_publishing_frequency" {
  type        = string
  default     = "FIFTEEN_MINUTES"
  description = "Specifies how often to publish updates to policy findings for the account. Valid values: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
}

variable "status" {
  type        = string
  default     = "ENABLED"
  description = "Specifies the status for the account. Valid values: ENABLED, PAUSED"
}

variable "findings_filters" {
  type = map(object({
    description = optional(string)
    action      = string # Valid values: ARCHIVE, NOOP
    position    = optional(number)
    finding_criteria = optional(object({
      criterion = optional(map(object({
        eq  = optional(list(string))
        gt  = optional(number)
        gte = optional(number)
        lt  = optional(number)
        lte = optional(number)
        neq = optional(list(string))
      })))
    }))
    tags = optional(map(string))
  }))
  default     = {}
  description = "Map of findings filters to create. Key is the filter name (which becomes the field name in criterion). The nested map key in criterion is the field name. If empty, no filters will be created."
}
