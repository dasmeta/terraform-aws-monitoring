variable "platform" {
  type        = string
  default     = "cloudwatch"
  description = "The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported"
}

variable "data_source_uid" {
  type        = string
  description = "The grafana dashboard widget item data source id"
}

variable "container" {
  type = string
}

variable "cluster" {
  type = string
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "account_id" {
  type    = string
  default = null
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

# stats
variable "period" {
  type    = number
  default = 300
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Allow to enable anomaly detection on widget metrics"
}
