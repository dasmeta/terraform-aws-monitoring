locals {
  cpu = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "name"      = item.name
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/cpu"]
  ]


  memory = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "name"      = item.name
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/memory"]
  ]

  restarts = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "name"      = item.name
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/restarts"]
  ]

  network = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "name"      = item.name
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/network"]
  ]
}

