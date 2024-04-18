locals {
  account_id         = ""
  zone_name          = ""
  balancer_name      = ""
  cdn_id             = ""
  container_1        = ""
  target_group_arn_1 = ""
  healthcheck_id_1   = ""
  rds                = ""
  cluster            = ""
  namespace          = ""
}

module "basic-dashboard-with-text" {
  source = "../../"
  name   = "dashboard-full-test"

  defaults = {
    cluster : local.cluster
  }
  rows = [
    // sla block
    [
      { type = "sla-slo-sli", width : 8, balancer_name = local.balancer_name }
    ],
    // dns block
    [
      { type : "text/title-with-link", text : "DNS Zone", link_to_jump = "https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=eu-central-1#ListRecordSets/xxxxxx" }
    ],
    [
      { type : "dns/queries-gauge", zone_name : local.zone_name },
      { type : "dns/queries-chart", width : 18, zone_name : local.zone_name },
    ],
    // cdn block
    [
      { type : "text/title-with-link", text : "CDN (CloudFront)", link_to_jump = "https://us-east-1.console.aws.amazon.com/cloudfront/v3/home?region=us-east-1#/distributions/xxxxxx" }
    ],
    [
      { type : "cloudfront/requests", distribution : local.cdn_id },
      { type : "cloudfront/errors", distribution : local.cdn_id },
      { type : "cloudfront/error-rate", distribution : local.cdn_id },
      { type : "cloudfront/traffic-bytes", distribution : local.cdn_id },
    ],
    // alb block
    [
      { type : "text/title-with-link", text : "Load Balancer (ALB)", link_to_jump = "https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LoadBalancer:loadBalancerArn=arn:aws:elasticloadbalancing:eu-central-1:xxxxxxxx:loadbalancer/app/xxxxx/xxxxxx;tab=listeners" }
    ],
    [
      { type : "balancer/request-count", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : false },
      { type : "balancer/2xx", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : false },
      { type : "balancer/4xx", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : false },
      { type : "balancer/5xx", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : false },
    ],
    [
      { type : "balancer/all-requests", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/unhealthy-request-count", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : true },
      { type : "balancer/error-rate", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection = false },
      { type : "balancer/connection-issues", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection = false },
    ],
    [
      { type : "balancer/response-time", accountId : local.account_id, balancer_name : local.balancer_name, width : 12 },
      { type : "balancer/traffic", accountId : local.account_id, balancer_name : local.balancer_name, width : 12 },
    ],
    // service block
    [
      { type : "text/title", text : "Superset" }
    ],
    [
      { type : "container/release-version", container : local.container_1, namespace : local.namespace, version_label : "app-version", log_group_name : "app-logs" },
      { type : "container/request-count", container : local.container_1, target_group_arn : local.target_group_arn_1 },
      { type : "container/all-requests", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_name : local.balancer_name },
      { type : "container/error-rate", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_name : local.balancer_name },
    ],
    [
      { type : "container/cpu", container : local.container_1 },
      { type : "container/memory", container : local.container_1 },
      { type : "container/network-in", container : local.container_1 },
      { type : "container/network-out", container : local.container_1 },
    ],
    [
      { type : "container/replicas", container : local.container_1, width : 8 },
      { type : "container/restarts", container : local.container_1, width : 8 },
      { type : "container/response-time", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_name : local.balancer_name, width : 8 },
      # { type : "container/network", container : local.container_1 },
    ],
    [
      { type : "container/health-check", container : local.container_1, target_group_arn : local.target_group_arn_1, balancer_name : local.balancer_name, width : 12 },
      { type : "container/external-health-check", container : local.container_1, healthcheck_id : local.healthcheck_id_1, width : 12 },
    ],
    // rds block
    [
      { type : "text/title-with-link", text : "RDS", link_to_jump = "https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#database:id;is-cluster=false;tab=connectivity" }
    ],
    [
      { type : "rds/free-storage", rds_name : local.rds },
      { type : "rds/connections", rds_name : local.rds, db_max_connections_count : 100 },
      { type : "rds/performance", rds_name : local.rds },
      { type : "rds/network", rds_name : local.rds },
    ],
    [
      { type : "rds/cpu", rds_name : local.rds, anomaly_detection : true },
      { type : "rds/iops", rds_name : local.rds },
      { type : "rds/swap", rds_name : local.rds },
      { type : "rds/disk-latency", rds_name : local.rds },
    ]
  ]
}
