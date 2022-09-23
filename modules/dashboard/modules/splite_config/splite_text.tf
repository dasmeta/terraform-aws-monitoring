locals {
  text = [for r, items in var.rows : [for k, item in items : {
    "content" : lookup(item, "content", "Text Widget"),
    "rows" = r
    "key"  = k
    } if item.type == "text"]
  ]
}
