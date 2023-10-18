variable "target_group_arn" {
  type    = string
  default = null
}

variable "balancer_arn" {
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
