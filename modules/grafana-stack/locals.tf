data "aws_region" "current" {}

locals {
  iam_username         = "${var.s3_bucket_prefix}-usr"
  tempo_bucket         = "${var.s3_bucket_prefix}-tempo"
  loki_bucket          = "${var.s3_bucket_prefix}-loki"
  service_account_name = "grafana-stack-sa-${var.s3_bucket_prefix}"
}
