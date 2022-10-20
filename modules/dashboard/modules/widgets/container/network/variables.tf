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
