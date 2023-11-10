output "result" {
  description = "description"
  value = var.balancer_name != null ? [
    [
      { type : "text/title", text : var.service_name }
    ],
    [
      { type : "container/request-count", container : var.service_name, target_group_arn : var.target_group_arn, cluster : var.cluster, namespace : var.namespace },
      { type : "container/all-requests", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster, namespace : var.namespace },
      { type : "container/error-rate", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster, namespace : var.namespace },
      { type : "container/health-check", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster, namespace : var.namespace },
    ],
    [
      { type : "container/cpu", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
      { type : "container/memory", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
      { type : "container/network-in", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
      { type : "container/network-out", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
    ],
    [
      { type : "container/external-health-check", container : var.service_name, healthcheck_id : var.healthcheck_id, cluster : var.cluster, namespace : var.namespace },
      { type : "container/replicas", container : var.service_name, cluster : var.cluster, namespace : var.namespace },
      { type : "container/restarts", container : var.service_name, cluster : var.cluster, namespace : var.namespace },
      { type : "container/response-time", container : var.service_name, target_group_arn : var.target_group_arn, balancer_name : var.balancer_name, cluster : var.cluster, namespace : var.namespace },
      # { type : "container/network", container : local.container_1 },
    ],
    ] : [
    [
      { type : "text/title", text : var.service_name }
    ],
    [
      { type : "container/cpu", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
      { type : "container/memory", container : var.service_name, cluster : var.cluster, namespace : var.namespace, anomaly_detection : true },
      { type : "container/replicas", container : var.service_name, cluster : var.cluster, namespace : var.namespace },
      { type : "container/restarts", container : var.service_name, cluster : var.cluster, namespace : var.namespace },
    ],
    [
      { type : "container/network-in", container : var.service_name, cluster : var.cluster, namespace : var.namespace, width : 12, anomaly_detection : true },
      { type : "container/network-out", container : var.service_name, cluster : var.cluster, namespace : var.namespace, width : 12, anomaly_detection : true },
    ]
  ]
}
