variable "name" {
  type        = string
  default     = "grafana-stack"
  description = "grafana stack release name"
}

variable "namespace" {
  type        = string
  default     = "monitoring"
  description = "The kubernetes namespace where grafana-stuck release will be created/installed"
}

variable "create_namespace" {
  type        = bool
  default     = true
  description = "Whether to create kubernetes namespace for grafana stack helm release"
}

variable "host" {
  type        = string
  description = "The ingress host name to have grafana ui available via load balancer"
}

variable "s3_bucket_prefix" {
  type        = string
  description = "The aws S3 storage/bucket name prefix to use while generating buckets for tempo and loki"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "The arn of oidc provider for eks cluster"
}

variable "adminPassword" {
  type        = string
  description = "The initial admin user password for using to login into grafana ui"
}