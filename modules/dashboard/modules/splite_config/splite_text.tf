locals {
  text = [for r, items in var.rows : [for k, item in items : {
    "content" : item.content,
    "rows" = r
    "key"  = k
    } if item.type == "text"]
  ]
}
