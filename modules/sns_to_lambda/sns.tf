module "topic" {
  #   source  = "dasmeta/sns/aws//modules/topic"
  #   version = "1.2.2"
  source     = "/Users/juliaaghamyan/Desktop/dasmeta/terraform-aws-sns/modules/topic"
  topic_name = var.topic_name
}

module "subscriptions" {
  source = "dasmeta/sns/aws//modules//subscription"
  #   version = "1.2.2"

  topic    = var.topic_name
  protocol = "lambda"
  endpoint = module.sns_to_servicenow.function_arn

  depends_on = [
    module.topic
  ]
}
