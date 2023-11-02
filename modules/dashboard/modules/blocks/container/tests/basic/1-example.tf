module "this" {
  source = "../../../../.."

  name = "container-block-test-dashboard"

  defaults = {
    cluster : "prod-6"
    anomaly_detection : true
  }

  rows = [
    {
      name : "superset",
      type : "block/container",
      target_group_arn : "arn:aws:elasticloadbalancing:eu-central-1:12345678999:targetgroup/k8s-default-04sd214d/asfa21412dass",
      balancer_name : "prod",
      healthcheck_id : "safcas234-12412-dsvsdc-4124da-8784d572893a"
    },
    {
      name : "superset",
      type : "block/container"
      target_group_arn : "arn:aws:elasticloadbalancing:eu-central-1:12345678999:targetgroup/k8s-default-04sd214d/asfa21412dass",
      balancer_name : "prod",
      healthcheck_id : "safcas234-12412-dsvsdc-4124da-8784d572893a"
    }
  ]
}
