data "aws_region" "current" {}
locals {
  cpu = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "name"   = lookup(item, "name", "${item.container} CPU")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Average")


    "metrics" = [
      ["ContainerInsights", "pod_cpu_utilization", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"])],
      ["ContainerInsights", "pod_cpu_reserved_capacity", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"]), { "color" : "#d62728" }]
    ]

    } if item.type == "container/cpu"]
  ]


  memory = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "name"   = lookup(item, "name", "${item.container} Memory")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Average")

    "metrics" = [
      ["ContainerInsights", "pod_memory_utilization", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"])],
      ["ContainerInsights", "pod_memory_reserved_capacity", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"]), { "color" : "#d62728" }]
    ]

    } if item.type == "container/memory"]
  ]

  restarts = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "name"   = lookup(item, "name", "${item.container} Restart")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Sum")

    "metrics" = [
      ["ContainerInsights", "pod_number_of_container_restarts", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"]), { "color" : "#d62728" }],
    ]

    } if item.type == "container/restarts"]
  ]

  network = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "name"   = lookup(item, "name", "${item.container} Network")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Average")

    "metrics" = [
      ["ContainerInsights", "pod_network_rx_bytes", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"]), { "color" : "#17becf" }],
      ["ContainerInsights", "pod_network_tx_bytes", "PodName", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"]), { "color" : "#e377c2" }]
    ]

    } if item.type == "container/network"]
  ]
}
