locals {
  log_base = [for r, items in var.rows : [for k, item in items : {
    "rows"   = r
    "key"    = k
    "type"   = item.type,
    "name"   = lookup(item, "name", "${item.custom_namespaces}/${item.metric_name}")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Average")

    "metrics" = [
      ["${item.custom_namespaces}", "${item.metric_name}"],
    ]

    } if item.type == "log_base"]
  ]
}
