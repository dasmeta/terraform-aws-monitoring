variable "container" {
  type    = string
  default = "Average"
}

# position
variable "coordinates" {
  type = map({
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

# region
variable "region" {
  type    = string
  default = ""
}
