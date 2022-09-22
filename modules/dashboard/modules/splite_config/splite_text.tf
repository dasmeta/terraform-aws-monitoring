locals {
  text = [for r, items in var.rows : [for k, item in items : {
    "content" : lookup(item, "name", "Text Widget"),
    "rows" = r
    "key"  = k

    } if item.type == "text"]
  ]
}
