variable "name" {
  type = string
}

variable "data_source_uid" {
  type        = string
  description = "The grafana dashboard widget item data source id"
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
