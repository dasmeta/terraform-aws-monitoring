data "aws_lb" "balancer" {
  name = var.balancer_name
}

output "result" {
  description = "description"
  value = [
    [
      { type : "text/title-with-link", text : "Load Balancer (${var.balancer_name})", link_to_jump = "https://${var.region}.console.aws.amazon.com/ec2/home?region=${var.region}#LoadBalancer:loadBalancerArn=${data.aws_lb.balancer.arn};tab=listeners" }
    ],
    [
      { type : "balancer/request-count", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection : false },
      { type : "balancer/2xx", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection : false },
      { type : "balancer/4xx", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection : false },
      { type : "balancer/5xx", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection : false },
    ],
    [
      { type : "balancer/all-requests", accountId : var.account_id, balancer_name : var.balancer_name },
      { type : "balancer/unhealthy-request-count", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection : false },
      { type : "balancer/error-rate", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection = false },
      { type : "balancer/connection-issues", accountId : var.account_id, balancer_name : var.balancer_name, anomaly_detection = false },
    ],
    [
      { type : "balancer/response-time", accountId : var.account_id, balancer_name : var.balancer_name, width : 12, anomaly_detection = true },
      { type : "balancer/traffic", accountId : var.account_id, balancer_name : var.balancer_name, width : 12, anomaly_detection = true },
    ],
  ]
}
