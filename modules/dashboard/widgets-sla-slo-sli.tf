# sla_slo_sli widgets
module "widget_sla_slo_sli" {
  source = "./modules/widgets/sla-slo-sli"

  count = length(local.sla_slo_sli)

  # coordinates
  coordinates = local.sla_slo_sli[count.index].coordinates

  # stats
  period = local.sla_slo_sli[count.index].period

  # one of balancer_name or balancer_arn should be passed, if both passed balancer_name is considered
  balancer_name = try(local.sla_slo_sli[count.index].balancer_name, null)
  balancer_arn  = try(local.sla_slo_sli[count.index].balancer_arn, null)

  account_id = try(local.sla_slo_sli[count.index].accountId, data.aws_caller_identity.project.account_id)
}
