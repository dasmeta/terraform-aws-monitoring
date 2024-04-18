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

variable "anomaly_deviation" {
  type        = number
  default     = 6
  description = "Deviation of the anomaly band"
}

variable "version_label" {
  type        = string
  description = "The label name which shows deployment version"
}

variable "namespace" {
  type        = string
  description = "The namespace where application is deployed"
}

variable "container" {
  type        = string
  description = "The application name"
}

variable "log_group_name" {
  type        = string
  description = "Log group name where applicaiton sends logs"
}
