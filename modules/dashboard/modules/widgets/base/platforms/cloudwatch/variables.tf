variable "name" {
  type = string
}

variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
}

variable "metrics" {
  type        = any
  default     = []
  description = "Metrics to be displayed on the widget."
}

variable "expressions" {
  type = list(object({
    expression = string
    label      = optional(string, null)
    accountId  = optional(string, null)
    visible    = optional(bool, null)
    color      = optional(string, null)
    yAxis      = optional(string, null)
    region     = optional(string, null)
    id         = optional(string, null)
  }))
  default     = []
  description = "Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids"
}

variable "yAxis" {
  type        = any
  default     = { left = { min = 0 } }
  description = "Widget Item common yAxis option (applied only metric type widgets)."
}

variable "defaults" {
  type        = any
  default     = {}
  description = "Default values that will be passed to all metrics."
}

variable "stat" {
  type    = string
  default = "Average"
}

variable "period" {
  type    = number
  default = 300
}

variable "region" {
  type    = string
  default = ""
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Allow to enable anomaly detection on widget metrics"
}

variable "anomaly_deviation" {
  type        = number
  default     = 6
  description = "Deviation of the anomaly band"
}

variable "type" {
  type        = string
  default     = "metric"
  description = "The type of widget to be prepared"
}

variable "query" {
  type        = string
  default     = null
  description = "The Logs Insights complete build query without sources and other options(in case of metric) query"
}

variable "sources" {
  type        = list(string)
  default     = []
  description = "Log groups list for Logs Insights query"
}

variable "view" {
  type        = string
  default     = null
  description = "The view for log insights and alarm widgets"
}

variable "stacked" {
  type        = bool
  default     = null
  description = "The stacked option for log insights and alarm widgets"
}

variable "annotations" {
  type        = any
  default     = null
  description = "The annotations option for alarm widgets"
}

variable "alarms" {
  type        = list(string)
  default     = null
  description = "The list of alarm_arns used for properties->alarms option in alarm widgets"
}

variable "properties_type" {
  type        = string
  default     = null
  description = "The properties->type option for alarm widgets"
}

variable "setPeriodToTimeRange" {
  type        = bool
  default     = null
  description = "setPeriodToTimeRange of widget"
}

variable "singleValueFullPrecision" {
  type        = bool
  default     = null
  description = "singleValueFullPrecision of widget"
}

variable "sparkline" {
  type        = bool
  default     = null
  description = "sparkline of widget"
}

variable "trend" {
  type        = bool
  default     = null
  description = "trend of widget"
}

variable "start" {
  type        = string
  default     = null
  description = "start of widget"
}

variable "end" {
  type        = string
  default     = null
  description = "end of widget"
}
