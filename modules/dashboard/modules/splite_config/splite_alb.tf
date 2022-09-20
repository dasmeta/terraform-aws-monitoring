locals {
  traffic_5xx = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "loadbalancer" = item.loadbalancer
    "name"         = lookup(item, "name", "${item.loadbalancer} 5xx")
    "rows"         = r
    "key"          = k
    "period"       = lookup(item, "period", 0)
    "region"       = lookup(item, "region", "")
    } if item.type == "traffic/5xx"]
  ]

  traffic_4xx = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "loadbalancer" = item.loadbalancer
    "name"         = lookup(item, "name", "${item.loadbalancer} 4xx")
    "rows"         = r
    "key"          = k
    "period"       = lookup(item, "period", 0)
    "region"       = lookup(item, "region", "")
    } if item.type == "traffic/4xx"]
  ]

  traffic_2xx = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "loadbalancer" = item.loadbalancer
    "name"         = lookup(item, "name", "${item.loadbalancer} 2xx")
    "rows"         = r
    "key"          = k
    "period"       = lookup(item, "period", 0)
    "region"       = lookup(item, "region", "")
    } if item.type == "traffic/2xx"]
  ]
}
