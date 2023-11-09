locals {
  # get all blocks and annotate
  initial_blocks = [
    for index1, block in var.rows : {
      block : block[0],
      index1 : index1,
      type : replace(block[0].type, "block/", "")
    } if strcontains(block[0].type, "block/")
  ]

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

  # bring all module results together
  blocks_results = {
    rds     = module.block_rds.*.result
    dns     = module.block_dns.*.result
    cdn     = module.block_cdn.*.result
    alb     = module.block_alb.*.result
    service = module.block_service.*.result
    sla     = module.block_sla.*.result
  }

  # annotate each block type with subIndex
  blocks_by_type = {
    rds     = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "rds")],
    dns     = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "dns")],
    cdn     = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "cdn")],
    alb     = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "alb")]
    service = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "service")]
    sla     = [for index2, block in local.initial_blocks : merge(block, { index2 : index2 }) if strcontains(block.type, "sla")]
  }
}

# get modules replace block with subset
module "block_rds" {
  source = "./modules/blocks/rds"

  count = length(local.blocks_by_type.rds)

  name                     = local.blocks_by_type.rds[count.index].block.name
  db_max_connections_count = local.blocks_by_type.rds[count.index].block.db_max_connections_count
  region                   = var.region != "" ? var.region : data.aws_region.current.name
}

module "block_dns" {
  source = "./modules/blocks/dns"

  count = length(local.blocks_by_type.dns)

  zone_name = local.blocks_by_type.dns[count.index].block.zone_name
}

module "block_cdn" {
  source = "./modules/blocks/cdn"

  count = length(local.blocks_by_type.cdn)

  cdn_id = local.blocks_by_type.cdn[count.index].block.cdn_id
}

module "block_alb" {
  source = "./modules/blocks/alb"

  count = length(local.blocks_by_type.alb)

  balancer_name = local.blocks_by_type.alb[count.index].block.balancer_name
  account_id    = local.blocks_by_type.alb[count.index].block.account_id
  region        = var.region != "" ? var.region : data.aws_region.current.name
}

module "block_service" {
  source = "./modules/blocks/service"

  count = length(local.blocks_by_type.service)

  service_name     = local.blocks_by_type.service[count.index].block.service_name
  balancer_name    = try(local.blocks_by_type.service[count.index].block.balancer_name, null)
  target_group_arn = try(local.blocks_by_type.service[count.index].block.target_group_arn, null)
  healthcheck_id   = try(local.blocks_by_type.service[count.index].block.healthcheck_id, null)
  cluster          = local.blocks_by_type.service[count.index].block.cluster
  namespace        = try(local.blocks_by_type.service[count.index].block.namespace, "default")
  region           = var.region != "" ? var.region : data.aws_region.current.name
}

module "block_sla" {
  source = "./modules/blocks/sla"

  count = length(local.blocks_by_type.sla)

  balancer_name = local.blocks_by_type.sla[count.index].block.balancer_name
  region        = var.region != "" ? var.region : data.aws_region.current.name
}
