variable "title" {
  type    = string
  default = null
}

variable "alarm_arn" {
  type        = string
  description = "The aws alarm arn to show metrics"
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
  default     = 4
  description = "Deviation of the anomaly band"
}
