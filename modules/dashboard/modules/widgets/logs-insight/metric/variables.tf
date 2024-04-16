variable "platform" {
  type        = string
  default     = "cloudwatch"
  description = "The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported"
}

variable "data_source_uid" {
  type        = string
  description = "The grafana dashboard widget item data source id"
}

variable "title" {
  type = string
}

variable "sources" {
  type        = list(string)
  description = "The list of log group paths"
}

variable "query" {
  type        = string
  description = "The Logs Insights query"
}

variable "stats" {
  type        = list(string)
  description = "The stats body for visualization"
}

variable "time_period" {
  type        = string
  default     = "5m"
  description = "The time period used as argument in function bin() to group the returned results by a time period, examples: '5m', '30s', '1h'"
}

variable "view" {
  type        = string
  description = "The type of chart to visualization stats data"
  default     = "timeSeries"
}

variable "stacked" {
  type        = bool
  default     = false
  description = "The stacked option for log insights widgets"
}

# position
variable "coordinates" {
  type = object({
    x : number
    y : number
    width : number
    height : number
  })
}

variable "account_id" {
  type    = string
  default = null
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Enables anomaly detection on widget metrics"
}

variable "anomaly_deviation" {
  type        = number
  default     = 6
  description = "Deviation of the anomaly band"
}
