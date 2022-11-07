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

variable "title" {
  type = string
}

variable "metrics" {
  type = list(string)
  ## sample form
  # [
  #   "certmanager_certificate_renewal_timestamp_seconds",
  #   "certmanager_certificate_ready_status",
  #   "certmanager_certificate_expiration_timestamp_seconds",
  # ]
}

variable "custom_dimension_metrics" {
  type    = list(any)
  default = []
  ## sample form with custom dimensions
  # [
  #   {
  #     MetricName = "certmanager_certificate_renewal_timestamp_seconds"
  #     status = "failed"
  #   }
  # ]
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

variable "period" {
  type    = number
  default = 300
}

variable "stat" {
  type    = string
  default = "Average"
}

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Enables anomaly detection on widget metrics"
}
