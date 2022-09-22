locals {
  application_metric = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "app"            = item.app
    "container_name" = item.container
    "metric_name"    = item.metric_name
    "name"           = lookup(item, "name", "${item.metric_name}")
    "rows"           = r
    "key"            = k
    "period"         = lookup(item, "period", 0)
    "region"         = lookup(item, "region", "")
    } if item.type == "application"]
  ]
}
