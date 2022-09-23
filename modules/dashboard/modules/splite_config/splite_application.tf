locals {
  application_metric = [for r, items in var.rows : [for k, item in items : {
    "rows"   = r
    "key"    = k
    "type"   = item.type,
    "name"   = lookup(item, "name", "${item.metric_name}")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Average")

    "metrics" = [
      ["ContainerInsights/Prometheus", item.metric_name, "app", lookup(item, "app", "${item.container}"), "container_name", item.container, "ClusterName", lookup(item, "clustername", var.defaults["clustername"]), "Namespace", lookup(item, "namespace", var.defaults["namespace"])]
    ]

    } if item.type == "application"]
  ]
}
