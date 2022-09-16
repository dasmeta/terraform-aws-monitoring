variable "name" {
  type    = string
  default = "test"
}

variable "topic_name" {
  type    = string
  default = "test_topic"
}

variable "lambda_envs" {
  type = any
  default = {
    SERVICENOW_AUTH   = ""
    SERVICENOW_DOMAIN = ""
    SERVICENOW_PATH   = ""
  }
}
