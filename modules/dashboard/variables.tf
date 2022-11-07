variable "name" {
  type = string

  description = "Dashboard name. Should not contain spaces and special chars."
}

variable "defaults" {
  type = any
  ## valid values
  # object({
  #     period    = number
  #     namespace = string
  #     cluster   = string
  #     width     = number
  #     height    = number
  #   }
  # )

  default = {}

  description = "Default values to be supplied to all modules."
}

variable "rows" {
  type = any

  description = "List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets."
}

variable "platform" {
  type        = string
  default     = "cloudwatch"
  description = "The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported"
}

variable "data_source_uid" {
  type        = string
  default     = null
  description = "The grafana dashboard widget item data source id, required for only grafana dashboards"
}
