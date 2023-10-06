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
  default     = true
  description = "Allow to enable anomaly detection on widget metrics"
}
