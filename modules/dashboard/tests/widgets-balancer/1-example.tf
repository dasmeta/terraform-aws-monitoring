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

    # If you only have one ALB in your account, you only need to specify the type of request
    # [
    #   {
    #     type : "balancer/2xx",
    #   },
    #   {
    #     type : "balancer/4xx",
    #   },
    #   {
    #     type : "balancer/5xx",
    #   }
    # ]

    # If you have multiple sa or want to display the metrics of another account, specify the ARN
    # [
    #   {
    #     type : "balancer/2xx",
    #     accountId: "287872424462"
    #     balancer_arn: "arn:aws:elasticloadbalancing:eu-central-1:287872424462:loadbalancer/app/alb-ingress/8e511b0b30612cdd"
    #   },
    #   {
    #     type : "balancer/4xx",
    #     accountId: "287872424462"
    #     balancer_arn: "arn:aws:elasticloadbalancing:eu-central-1:287872424462:loadbalancer/app/alb-ingress/8e511b0b30612cdd"
    #   },
    #   {
    #     type : "balancer/5xx",
    #     accountId: "287872424462"
    #     balancer_arn: "arn:aws:elasticloadbalancing:eu-central-1:287872424462:loadbalancer/app/alb-ingress/8e511b0b30612cdd"
    #   }
    # ]
  ]

  # depends_on = [
  #   module.alb
  # ]
}
