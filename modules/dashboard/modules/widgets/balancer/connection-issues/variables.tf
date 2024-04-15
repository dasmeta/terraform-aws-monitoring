variable "balancer_name" {
  type    = string
  default = null
}

variable "balancer_arn" {
  type    = string
  default = null
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

variable "anomaly_deviation" {
  type        = number
  default     = 4
  description = "Deviation of the anomaly band"
}
