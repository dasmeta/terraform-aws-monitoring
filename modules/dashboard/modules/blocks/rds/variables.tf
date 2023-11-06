variable "name" {
  type        = string
  description = "RDS name"
}

variable "db_max_connections_count" {
  type        = string
  description = "RDS maximum connection count"
  default     = null
}

variable "region" {
  type    = string
  default = ""
}
