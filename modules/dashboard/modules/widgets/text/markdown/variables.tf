variable "text" {
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

variable "transparent-background" {
  type    = bool
  default = true
}
