output "result" {
  description = "description"
  value = [
    [
      { type : "text/title", text : var.service_name }
    ],
    [
      { type : "container/request-count", container : var.service_name, target_group_arn : var.target_group_arn, cluster : var.cluster },
      { type : "container/all-requests", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster },
      { type : "container/error-rate", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster },
      { type : "container/health-check", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster },
    ],
    [
      { type : "container/cpu", container : var.service_name, cluster : var.cluster },
      { type : "container/memory", container : var.service_name, cluster : var.cluster },
      { type : "container/network-in", container : var.service_name, cluster : var.cluster },
      { type : "container/network-out", container : var.service_name, cluster : var.cluster },
    ],
    [
      { type : "container/external-health-check", container : var.service_name, healthcheck_id : var.healthcheck_id, cluster : var.cluster },
      { type : "container/replicas", container : var.service_name, cluster : var.cluster },
      { type : "container/restarts", container : var.service_name, cluster : var.cluster },
      { type : "container/response-time", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster },
      # { type : "container/network", container : local.container_1 },
    ],
  ]
}
