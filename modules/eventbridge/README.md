## What

Our module is stream AWS Support events into our task management system.

## Example

```terraform
module "monitoring_billing" {
  source  = "dasmeta/monitoring/aws//modules/eventbridge"
  version = "0.0.1"

  account   = "000000000"             #your account ID
  name      = "EventToSNS"            #the name of SNS topic
  protocol  = "https"                 #sns protocol
  endpoint  = "https://xxxxxx"        #sns endpoint
}
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.eventtosns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.eventtosns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_sns_topic.eventtosns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.eventtosns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.snstoservicedesk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | n/a | `string` | `"565580475168"` | no |
| <a name="input_endpoint"></a> [endpoint](#input\_endpoint) | n/a | `string` | `"https://api.opsgenie.com/v1/json/cloudwatchevents?apiKey=c2913e4b-375f-41d5-ad1f-c1da5600f938"` | no |

## Outputs

No outputs.