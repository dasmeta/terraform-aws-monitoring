locals {
  balancer_name = "prod"
  account_id    = "123456789"
}

module "dashboard-with-balancer-metrics" {
  source = "../../"
  name   = "dashboard-with-balancer-metrics-test"

  defaults = {
    period : 300
    anomaly_detection : false
  }

  rows = [
    [
      { type : "text/title", text : "Load Balancer (ALB)" }
    ],

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
    [
      { type : "balancer/2xx", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/4xx", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/5xx", accountId : local.account_id, balancer_name : local.balancer_name },
    ],
    [
      { type : "balancer/traffic", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/response-time", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/unhealthy-request-count", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection : true },
      { type : "balancer/request-count", accountId : local.account_id, balancer_name : local.balancer_name },
    ],
    [
      { type : "balancer/all-requests", accountId : local.account_id, balancer_name : local.balancer_name },
      { type : "balancer/error-rate", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection = false },
      { type : "balancer/connection-issues", accountId : local.account_id, balancer_name : local.balancer_name, anomaly_detection = false },
    ]
  ]
}
