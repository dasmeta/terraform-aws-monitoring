locals {
  # get all blocks and annotate
  initial_blocks = [
    for index1, block in var.rows : {
      block : block[0],
      index1 : index1,
      type : replace(block[0].type, "block/", "")
    } if strcontains(block[0].type, "block/")
  ]

  # annotate each block type with subIndex
  blocks_by_type = {
    rds = [
      for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "rds")
    ],
    sqs = [
      for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "sqs")
    ]
  }
}

# get modules replace block with subset
module "block_rds" {
  source = "./modules/blocks/rds"

  count = length(local.blocks_by_type.rds)

  # coordinates
  name = local.blocks_by_type.rds[count.index].block.name
  # coordinates = local.alarm_status[count.index].coordinates

  # # metric
  # title = local.alarm_status[count.index].title

  # alarm_arns = local.alarm_status[count.index].alarm_arns
  # stacked    = try(local.alarm_status[count.index].stacked, false)

  # account_id        = try(local.alarm_status[count.index].accountId, null)
  # anomaly_detection = try(local.alarm_status[count.index].anomaly_detection, false)
}

module "block_sqs" {
  source = "./modules/blocks/sqs"

  count = length(local.blocks_by_type.sqs)

  # coordinates
  name = local.blocks_by_type.sqs[count.index].block.name
  # coordinates = local.alarm_status[count.index].coordinates

  # # metric
  # title = local.alarm_status[count.index].title

  # alarm_arns = local.alarm_status[count.index].alarm_arns
  # stacked    = try(local.alarm_status[count.index].stacked, false)

  # account_id        = try(local.alarm_status[count.index].accountId, null)
  # anomaly_detection = try(local.alarm_status[count.index].anomaly_detection, false)
}

locals {
  # bring all module results together
  blocks_results = {
    rds = module.block_rds.*.result
    sqs = module.block_sqs.*.result
  }

  blocks_by_type_results = concat([
    for type_blocks in local.blocks_by_type : [
      for index3, block in type_blocks : merge(block, { results : local.blocks_results[block.type][index3] })
    ]
  ]...)

  rows = concat([
    for index1, row in var.rows : strcontains(row[0].type, "block/") ?
    concat([
      for item in local.blocks_by_type_results : item.results if item.index1 == index1
    ]...)
    : [row]
  ]...)
}
