locals {
  traffic_5xx = [for r, items in var.rows : [for k, item in items : {
    "rows" = r
    "key"  = k
    "type" : item.type,
    "name"   = lookup(item, "name", "${item.loadbalancer} 5xx")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Sum")

    "metrics" = [
      ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${item.loadbalancer}"],
      ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#d62728" }],
      ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ff9896" }],
    ]
    } if item.type == "traffic/5xx"]
  ]

  traffic_4xx = [for r, items in var.rows : [for k, item in items : {
    "rows"   = r
    "key"    = k
    "type"   = item.type,
    "name"   = lookup(item, "name", "${item.loadbalancer} 4xx")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Sum")

    "metrics" = [
      ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${item.loadbalancer}"],
      ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ff7f0e" }],
      ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ffbb78" }],
    ]

    } if item.type == "traffic/4xx"]
  ]

  traffic_2xx = [for r, items in var.rows : [for k, item in items : {
    "rows"   = r
    "key"    = k
    "type"   = item.type,
    "name"   = lookup(item, "name", "${item.loadbalancer} 2xx")
    "width"  = lookup(item, "width", var.defaults["width"])
    "height" = lookup(item, "height", var.defaults["height"])
    "period" = lookup(item, "period", var.defaults["period"])
    "region" = lookup(item, "region", data.aws_region.current.name)
    "stat"   = lookup(item, "statistic", "Sum")

    "metrics" = [
      ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${item.loadbalancer}"],
      ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#2ca02c" }],
      ["AWS/ApplicationELB", "HTTPCode_ELB_2XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#98df8a" }],
    ]

    } if item.type == "traffic/2xx"]
  ]
}
