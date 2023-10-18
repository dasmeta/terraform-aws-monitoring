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

variable "healthcheck_id" {
  type    = string
  default = ""
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Allow to enable anomaly detection on widget metrics"
}
