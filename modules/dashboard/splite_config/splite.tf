locals {
  cpu = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/cpu"]
    ]
  ]

  memory = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/memory"]
    ]
  ]

  restarts = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/restarts"]
    ]
  ]

  network = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/network"]
    ]
  ]

  traffic = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    "period"    = lookup(item, "period", 0)
    "region"    = lookup(item, "region", "")
    } if item.type == "container/traffic"]
    ]
  ]

  text = [for r, items in var.rows : [for k1, itemss in items : [for k, item in itemss : {
    "content" : item.content,
    "rows" = r
    "key"  = k
    } if item.type == "text"]
    ]
  ]
}

