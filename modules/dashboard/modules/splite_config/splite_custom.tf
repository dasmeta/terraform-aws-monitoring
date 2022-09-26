locals {
  custom_metric = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "source"  = item.source
    "metrics" = [split("//", item.source)]
    "width"   = lookup(item, "width", var.defaults["width"])
    "height"  = lookup(item, "height", var.defaults["height"])
    "name"    = lookup(item, "name", "Custom Metric")
    "period"  = lookup(item, "period", var.defaults["period"])
    "region"  = lookup(item, "region", data.aws_region.current.name)
    "stat"    = lookup(item, "statistic", "Average")
    } if item.type == "custom"]
  ]
}
