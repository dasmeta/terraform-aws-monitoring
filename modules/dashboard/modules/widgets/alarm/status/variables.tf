variable "title" {
  type = string
}

variable "alarm_arns" {
  type = list(string)
  ## sample form
  # [
  #   "arn:aws:cloudwatch:eu-central-1:684806417680:alarm:684806417680-container-has-too-many-errors"
  #   "arn:aws:cloudwatch:eu-central-1:684806417680:alarm:CloudTrailChanges"
  #   "arn:aws:cloudwatch:eu-central-1:684806417680:alarm:RootLogin"
  # ]
  description = "The list of aws alarms to show status"
}

variable "type" {
  type        = string
  default     = "alarm"
  description = "There are two type of visualizations of alarms on dashboard: 'alarm' - displays only current status, 'metric' - shows chart with metric of alarm"
}

variable "stacked" {
  type        = bool
  default     = false
  description = "The stacked option for log insights widgets"
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

variable "anomaly_deviation" {
  type        = number
  default     = 4
  description = "Deviation of the anomaly band"
}
