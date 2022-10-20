variable "title" {
  type = string
}

variable "metrics" {
  type = list(any)
  ## sample form
  # [
  #   { MetricName = "errors1", "ClusterName": "my-cluster-name" },
  #   { MetricName = "errors2", "color" = "#d62728" }
  #   { MetricName = "errors3", accountId = "12335657657657",  "color" = "#d62728" }
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

variable "anomaly_detection" {
  type        = bool
  default     = false
  description = "Enables anomaly detection on widget metrics"
}
