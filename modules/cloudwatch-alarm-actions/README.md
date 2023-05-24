# This module allows to create an aws SNS topic and multiple email/sms/https/slack-lambda/servicenow-lambda subscriptions to forward cloudwatch alerts/alarms to. It is supposed that this module will be used aloconjunctionnt

# Example

```hcl
module "monitoring_cloudwatch_alarm_actions" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-alarm-actions"
  version = "x.y.z"

  web_endpoints = ["https://api.opsgenie.com/v1/json/cloudwatch?apiKey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.16 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dead_letter_queue"></a> [dead\_letter\_queue](#module\_dead\_letter\_queue) | dasmeta/modules/aws//modules/sqs | 1.5.1 |
| <a name="module_fallback-topic"></a> [fallback-topic](#module\_fallback-topic) | dasmeta/sns/aws//modules/topic | 1.0.0 |
| <a name="module_notify_servicenow"></a> [notify\_servicenow](#module\_notify\_servicenow) | ./modules/lambda-subscription | n/a |
| <a name="module_notify_slack"></a> [notify\_slack](#module\_notify\_slack) | terraform-aws-modules/notify-slack/aws | 5.4.1 |
| <a name="module_notify_teams"></a> [notify\_teams](#module\_notify\_teams) | ./modules/lambda-subscription | n/a |
| <a name="module_topic"></a> [topic](#module\_topic) | dasmeta/sns/aws//modules/topic | 1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_topic"></a> [create\_topic](#input\_create\_topic) | Whether to create sns topic | `bool` | `true` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | The SNS topic delivery policy | `any` | <pre>{<br>  "http": {<br>    "defaultHealthyRetryPolicy": {<br>      "backoffFunction": "linear",<br>      "maxDelayTarget": 20,<br>      "minDelayTarget": 20,<br>      "numMaxDelayRetries": 0,<br>      "numMinDelayRetries": 0,<br>      "numNoDelayRetries": 0,<br>      "numRetries": 3<br>    },<br>    "defaultThrottlePolicy": {<br>      "maxReceivesPerSecond": 1<br>    },<br>    "disableSubscriptionOverrides": false<br>  }<br>}</pre> | no |
| <a name="input_email_addresses"></a> [email\_addresses](#input\_email\_addresses) | List of email addresses to send notification to | `list(string)` | `[]` | no |
| <a name="input_enable_dead_letter_queue"></a> [enable\_dead\_letter\_queue](#input\_enable\_dead\_letter\_queue) | Whether to enable dead letter queue | `bool` | `true` | no |
| <a name="input_fallback_email_addresses"></a> [fallback\_email\_addresses](#input\_fallback\_email\_addresses) | List of fallback email addresses to send notification when lambda failed | `list(string)` | `[]` | no |
| <a name="input_fallback_phone_numbers"></a> [fallback\_phone\_numbers](#input\_fallback\_phone\_numbers) | List of international formatted phone number to send notification when lambda failed | `list(string)` | `[]` | no |
| <a name="input_fallback_web_endpoints"></a> [fallback\_web\_endpoints](#input\_fallback\_web\_endpoints) | List of web webhooks endpoints (like opsgenie) to send notification when lambda failed | `list(string)` | `[]` | no |
| <a name="input_lambda_failed_alert"></a> [lambda\_failed\_alert](#input\_lambda\_failed\_alert) | Alert for lambda failed | `any` | <pre>{<br>  "equation": "gte",<br>  "period": 60,<br>  "statistic": "sum",<br>  "threshold": 1<br>}</pre> | no |
| <a name="input_log_group_retention_days"></a> [log\_group\_retention\_days](#input\_log\_group\_retention\_days) | The count of days that cloudwatch log group will keep each log item and then will cleanup automatically | `number` | `7` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | log level for python code | `string` | `"INFO"` | no |
| <a name="input_phone_numbers"></a> [phone\_numbers](#input\_phone\_numbers) | List of international formatted phone number to send notification to | `list(string)` | `[]` | no |
| <a name="input_recreate_missing_package"></a> [recreate\_missing\_package](#input\_recreate\_missing\_package) | Whether to recreate missing Lambda package if it is missing locally or not | `bool` | `true` | no |
| <a name="input_servicenow_webhooks"></a> [servicenow\_webhooks](#input\_servicenow\_webhooks) | List of servicenow webhook configs to send notification to | <pre>list(object({<br>    domain = string<br>    path   = string<br>    user   = string<br>    pass   = string<br>  }))</pre> | `[]` | no |
| <a name="input_slack_webhooks"></a> [slack\_webhooks](#input\_slack\_webhooks) | List of slack webhook configs to send notification to | <pre>list(object({<br>    hook_url = string<br>    channel  = string<br>    username = string<br>  }))</pre> | `[]` | no |
| <a name="input_teams_webhooks"></a> [teams\_webhooks](#input\_teams\_webhooks) | Teams webhook configs to send notification to | `list(string)` | `[]` | no |
| <a name="input_topic_name"></a> [topic\_name](#input\_topic\_name) | The SNS topic name | `string` | `"cloudwatch-alerts"` | no |
| <a name="input_web_endpoints"></a> [web\_endpoints](#input\_web\_endpoints) | List of web webhooks endpoints (like opsgenie) to send notification to | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_topic_arn"></a> [topic\_arn](#output\_topic\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
