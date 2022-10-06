# data "aws_vpcs" "vpcs" {}

# data "aws_subnet_ids" "subnets" {
#   vpc_id = data.aws_vpcs.vpcs.ids[0]
# }

# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "~> 6.0"

#   name = "my-alb"

#   load_balancer_type = "application"

#   vpc_id  = data.aws_vpcs.vpcs.ids[0]
#   subnets = data.aws_subnet_ids.subnets.ids
# }

module "dashboard-with-balancer-metrics" {
  source = "../../"
  name   = "dashboard-with-balancer-metrics"

  defaults = {
    period : 300
  }

  rows = [
    # [
    #   {
    #     type : "balancer/2xx",
    #     balancer : "my-alb"
    #   },
    #   {
    #     type : "balancer/4xx",
    #     balancer : "my-alb"
    #   },
    #   {
    #     type : "balancer/5xx",
    #     balancer : "my-alb"
    #   }
    # ]
  ]

  # depends_on = [
  #   module.alb
  # ]
}
