locals {
  cpu = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/cpu"]
  ]

  memory = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/memory"]
  ]

  restarts = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/restarts"]
  ]

  network = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/network"]
  ]

  disk = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/disk"]
  ]

  traffic = [for r, items in var.rows : [for k, item in items : {
    "type" : item.type,
    "container" = item.container
    "rows"      = r
    "key"       = k
    } if item.type == "container/traffic"]
  ]

  text = [for r, items in var.rows : [for k, item in items : {
    "content" : item.content,
    "rows" = r
    "key"  = k
    } if item.type == "text"]
  ]
}

