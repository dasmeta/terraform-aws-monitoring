# module "vpc" {
#   source = "dasmeta/modules/aws//modules/vpc/examples/minimal-vpc"
# }

# module "alb" {
#   source  = "terraform-aws-modules/alb/aws"
#   version = "8.1.0"
#   depends_on = [
#     module.vpc
#   ]
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
