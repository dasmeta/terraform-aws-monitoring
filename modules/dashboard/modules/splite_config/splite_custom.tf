locals {
  custom_metric = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "source" = item.source
    "name"   = lookup(item, "name", "Custom Metric")
    "rows"   = r
    "key"    = k
    "period" = lookup(item, "period", 0)
    "region" = lookup(item, "region", "")
    } if item.type == "custom"]
  ]
}
