data "aws_lb" "balancer" {
  name = var.balancer_name
}

output "result" {
  description = "description"
  value = [
    [
      { type = "sla-slo-sli", width : 8, balancer_name = var.balancer_name }
    ]
  ]
}
