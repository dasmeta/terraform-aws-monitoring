locals {
  original_rows = [
    [{ type : "block/rds", name : "a" }],
    [{ type : "widget", name : "a1" }, { type : "widget", name : "a2" }],
    [{ type : "block/sqs", name : "b" }],
    [{ type : "widget", name : "b1" }, { type : "widget", name : "b2" }],
    [{ type : "block/sqs", name : "c" }],
  ]

  block_templates = {
    rds = [
      [{ type : "widget/r1" }, { type : "widget/r2" }, { type : "widget/r3" }],
      [{ type : "widget/r4" }, { type : "widget/r5" }],
    ],
    sqs = [
      [{ type : "widget/s1" }, { type : "widget/s2" }],
      [{ type : "widget/s1" }, { type : "widget/s2" }],
    ]
  }

  blocks = [
    for index, block in local.original_rows :
    {
      "block" : block[0],
      "index" : index,
      "type" : replace(block[0].type, "block/", "")
      contents : local.block_templates[replace(block[0].type, "block/", "")]
    }
    if strcontains(block[0].type, "block/")
  ]

  # blocks_by_type = { for block in local.blocks : block.block.type => [for item in local.blocks : item if item.block.type == block.block.type]... }

  replaced_rows = concat([
    for index, block in local.original_rows : strcontains(block[0].type, "block/") ?
    concat([
      for item in local.blocks : item.contents if item.index == index
    ]...)
    : [block]
  ]...)

  new_rows = concat([
    for block in local.original_rows : strcontains(block[0].type, "block/") ? [
      for block_row in local.block_templates[replace(block[0].type, "block/", "")] : [
        for widget in block_row : merge(block[0], widget)
      ]
    ]
    : [block]
  ]...)
  # new_rows = [for item in local.original_rows : (strcontains(try(item.type, ""), "block") ? tolist([item]) : tolist(item))]

  original_list = [
    "a",
    "b",
    "c",
  ]

  index_of_b = index(local.original_list, "b")

  before_b = slice(local.original_list, 0, local.index_of_b)
  after_b  = slice(local.original_list, local.index_of_b + 1, length(local.original_list))

  new_list = concat(local.before_b, ["b1", "b2"], local.after_b)
}
