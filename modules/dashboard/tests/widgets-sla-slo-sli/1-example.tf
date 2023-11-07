module "this" {
  source = "../../"
  name   = "dashboard-with-sla-slo-sli-metrics"
  rows = [
    [
      {
        width = 8
        type  = "sla-slo-sli",
        # balancer_name = "name-of-my-balancer" # you can use one of both balancer_name and balancer_arn params
        balancer_name = "alb_name"
      }
    ]
  ]
}
