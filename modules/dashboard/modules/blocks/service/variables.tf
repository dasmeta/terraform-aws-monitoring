variable "service_name" {
  type        = string
  description = "Service nameD"
}

variable "balancer_name" {
  type        = string
  description = "ALB name"
}

variable "target_group_arn" {
  type        = string
  description = "Target group ARN which points to the service"
}

variable "healthcheck_id" {
  type        = string
  description = "R53 healthcheck ID for the service"
}

variable "cluster" {
  type        = string
  description = "EKS cluster name"
}

variable "region" {
  type    = string
  default = ""
}
