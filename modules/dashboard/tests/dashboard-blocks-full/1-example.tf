module "this" {
  source = "../.."

  name = "test-dashboard-with-blocks"

  rows = [
    [{ "type" : "block/sla", "balancer_name" : "" }],
    [{ "type" : "block/dns", "zone_name" : "" }],
    [{ "type" : "block/cdn", "cdn_id" : "xxxxxxxxx" }],
    [{ "type" : "block/alb", "balancer_name" : "", account_id : "xxxxxxxxx" }],
    [{ "type" : "block/service", service_name : "", cluster : "prod", version_label = "app-version", log_group_name = "eks-dev-application", balancer_name : "", target_group_arn : "xxxxxxxxx", healthcheck_id : "xxxxxxxxx" }],
    [{ "type" : "block/rds", "name" : "", db_max_connections_count : 100 }],
    [{ "type" : "block/redis", "name" : "" }],
  ]
}
