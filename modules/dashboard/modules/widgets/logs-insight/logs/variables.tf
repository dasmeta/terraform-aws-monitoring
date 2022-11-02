variable "title" {
  type = string
}

variable "sources" {
  type        = list(string)
  description = "The list of log group paths"
}

variable "query" {
  type        = string
  description = "The Logs Insights query"
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

variable "account_id" {
  type    = string
  default = null
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Enables anomaly detection on widget metrics"
}
