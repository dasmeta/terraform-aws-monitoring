variable "title" {
  type = string
}

variable "metrics" {
  type = any
  ## sample form
  # [
  #   { MetricName = "errors1", "ClusterName" = "my-cluster-name" },
  #   { MetricName = "errors2", "color" = "#d62728" }
  #   { MetricName = "errors3", accountId : "123234365765", "color" = "#d62728" }
  # ]
}

variable "expressions" {
  type = list(object({
    expression = string
    label      = optional(string, null)
    accountId  = optional(string, null)
    visible    = optional(bool, null)
    color      = optional(string, null)
    yAxis      = optional(string, null)
    region     = optional(string, null)
  }))
  default     = []
  description = "Custom metric expressions over metrics, note that metrics have auto generated m1,m2,..., m{n} ids"
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

variable "yAxis" {
  type        = any
  default     = { left = { min = 0 } }
  description = "Widget Item common yAxis option (applied only metric type widgets)."
}
