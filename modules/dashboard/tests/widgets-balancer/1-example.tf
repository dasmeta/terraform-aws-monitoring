module "dashboard-with-balancer-metrics" {
  source = "../../"
  name   = "dashboard-with-balancer-metrics"

  defaults = {
    period : 300
  }

  rows = [
    [
      {
        type : "balancer/2xx",
        balancer : "balancer-1"
      },
      {
        type : "balancer/4xx",
        balancer : "balancer-1"
      },
      {
        type : "balancer/5xx",
        balancer : "balancer-1"
      }
    ]
  ]
}
