variable "platform" {
  type        = string
  default     = "cloudwatch"
  description = "The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported"
}

variable "data_source_uid" {
  type        = string
  description = "The grafana dashboard widget item data source id"
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

variable "rds_name" {
  type        = string
  description = "Database name"
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Allow to enable anomaly detection on widget metrics"
}

variable "db_max_connections_count" {
  type        = number
  description = "RDS connection's maximum count"
  default     = null
}
