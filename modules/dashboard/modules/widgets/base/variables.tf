variable "name" {
  type = string
}

variable "x" {
  type        = number
  description = "Horizontal position in the grid. Can be between 0-23."
}

variable "y" {
  type        = number
  description = "Vertical position in the grid. Must be positive number starting from 0."
}

variable "width" {
  type        = number
  default     = 2
  description = "Horizontal size of the widget in the grid. Value is from 1-23."
}

variable "height" {
  type        = number
  default     = 2
  description = "Vertical size of the widget in the grid. Value is from 1 to any value."
}

variable "metrics" {
  type        = list(list(string))
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
