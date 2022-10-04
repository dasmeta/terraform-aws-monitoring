variable "name" {
  type = string
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
