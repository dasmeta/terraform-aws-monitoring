module "aws_cloudwatch_log_metric_filter" {
  source = "./modules/cloudwatch-log-based-metrics"

  metrics_patterns = var.log_base_metrics
}
