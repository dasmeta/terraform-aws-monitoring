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

# region
variable "region" {
  type    = string
  default = ""
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
variable "stat" {
  type    = string
  default = "Average"
}

variable "period" {
  type    = number
  default = 300
}
