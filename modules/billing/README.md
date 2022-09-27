## What

Our module is seting up billing alert to opsgenie and budget limit.

## MUST BE

Make sure that the cloudwatch is in the eu-east-1 region.

## Minimal Example

```terraform
module "monitoring_billing" {
  source  = "dasmeta/monitoring/aws//modules/billing"
  version = "0.2.1"

  name = "Account Monthly Budget"
  sns_subscription_email_address_list = ["example@gmail.com"]
  sns_subscription_phone_number_list  = ["000000000"]
  opsgenie_endpoint = ["https://xxxxxxx"]
}
```

## Minimal Example

```terraform
module "monitoring_billing" {
  source  = "dasmeta/monitoring/aws//modules/billing"
  version = "0.2.1"

  name = "Account Monthly Budget"
  account_budget_limit = "200"
  limit_unit = "USD"
  time_unit = "MONTHLY"
  sns_subscription_email_address_list = ["example@gmail.com"]
  sns_subscription_phone_number_list  = ["000000000"]
  opsgenie_endpoint = ["https://xxxxxxx"]
  slack_hook_url = ["https://xxxxxxx"]
  metric_name = "EstimatedCharges"
  alarm_name = "Billing-alarm"
  threshold = "200"
  comparison_operator = "GREATER_THAN"
}
```

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alert-notify-slack"></a> [alert-notify-slack](#module\_alert-notify-slack) | terraform-aws-modules/notify-slack/aws | 4.18.0 |

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.budget_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_cloudwatch_metric_alarm.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.alerts-notify-email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts-notify-opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts-notify-sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_budget_limit"></a> [account\_budget\_limit](#input\_account\_budget\_limit) | n/a | `string` | `"200"` | no |
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | n/a | `string` | `"Billing-alarm"` | no |
| <a name="input_budget_type"></a> [budget\_type](#input\_budget\_type) | n/a | `string` | `"COST"` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Specifies the number of days you want to retain log events in log group for Lambda. | `number` | `0` | no |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | n/a | `string` | `"GREATER_THAN"` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `string` | `"1"` | no |
| <a name="input_limit_unit"></a> [limit\_unit](#input\_limit\_unit) | n/a | `string` | `"USD"` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | n/a | `string` | `"EstimatedCharges"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"Account-Monthly-Budget"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"Billing"` | no |
| <a name="input_notification_type"></a> [notification\_type](#input\_notification\_type) | n/a | `string` | `"ACTUAL"` | no |
| <a name="input_opsgenie_endpoint"></a> [opsgenie\_endpoint](#input\_opsgenie\_endpoint) | Opsigenie platform integration url | `list(string)` | <pre>[<br>  "https://api.opsgenie.com/v1/json/amazonsns?apiKey=5736f9c8-409d-4b67-b922-45926096bf54"<br>]</pre> | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"28800"` | no |
| <a name="input_slack_channel"></a> [slack\_channel](#input\_slack\_channel) | Slack Channel | `string` | `""` | no |
| <a name="input_slack_hook_url"></a> [slack\_hook\_url](#input\_slack\_hook\_url) | This is slack webhook url path without domain | `string` | `""` | no |
| <a name="input_slack_username"></a> [slack\_username](#input\_slack\_username) | Slack User Name | `string` | `""` | no |
| <a name="input_sms_message_body"></a> [sms\_message\_body](#input\_sms\_message\_body) | n/a | `string` | `"sms_message_body"` | no |
| <a name="input_sns_subscription_email_address_list"></a> [sns\_subscription\_email\_address\_list](#input\_sns\_subscription\_email\_address\_list) | List of email addresses | `list(string)` | <pre>[<br>  "katrin@dasmeta.com"<br>]</pre> | no |
| <a name="input_sns_subscription_phone_number_list"></a> [sns\_subscription\_phone\_number\_list](#input\_sns\_subscription\_phone\_number\_list) | List of telephone numbers to subscribe to SNS. | `list(string)` | <pre>[<br>  "+37499091710"<br>]</pre> | no |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | n/a | `string` | `"Maximum"` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | n/a | `string` | `"200"` | no |
| <a name="input_threshold_type"></a> [threshold\_type](#input\_threshold\_type) | n/a | `string` | `"PERCENTAGE"` | no |
| <a name="input_time_period_end"></a> [time\_period\_end](#input\_time\_period\_end) | n/a | `string` | `"2087-06-15_00:00"` | no |
| <a name="input_time_period_start"></a> [time\_period\_start](#input\_time\_period\_start) | n/a | `string` | `"2022-01-01_00:00"` | no |
| <a name="input_time_unit"></a> [time\_unit](#input\_time\_unit) | n/a | `string` | `"MONTHLY"` | no |

## Outputs

No outputs.## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alert-notify-slack"></a> [alert-notify-slack](#module\_alert-notify-slack) | terraform-aws-modules/notify-slack/aws | 4.18.0 |

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.budget_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_cloudwatch_metric_alarm.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.alerts-notify-email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts-notify-opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts-notify-sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_budget_limit"></a> [account\_budget\_limit](#input\_account\_budget\_limit) | n/a | `string` | `"200"` | no |
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | n/a | `string` | `"Billing-alarm"` | no |
| <a name="input_budget_type"></a> [budget\_type](#input\_budget\_type) | n/a | `string` | `"COST"` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Specifies the number of days you want to retain log events in log group for Lambda. | `number` | `0` | no |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | n/a | `string` | `"GREATER_THAN"` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `string` | `"1"` | no |
| <a name="input_limit_unit"></a> [limit\_unit](#input\_limit\_unit) | n/a | `string` | `"USD"` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | n/a | `string` | `"EstimatedCharges"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"Account-Monthly-Budget"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"Billing"` | no |
| <a name="input_notification_type"></a> [notification\_type](#input\_notification\_type) | n/a | `string` | `"ACTUAL"` | no |
| <a name="input_opsgenie_endpoint"></a> [opsgenie\_endpoint](#input\_opsgenie\_endpoint) | Opsigenie platform integration url | `list(string)` | <pre>[<br>  "https://api.opsgenie.com/v1/json/amazonsns?apiKey=5736f9c8-409d-4b67-b922-45926096bf54"<br>]</pre> | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"28800"` | no |
| <a name="input_slack_channel"></a> [slack\_channel](#input\_slack\_channel) | Slack Channel | `string` | `""` | no |
| <a name="input_slack_hook_url"></a> [slack\_hook\_url](#input\_slack\_hook\_url) | This is slack webhook url path without domain | `string` | `""` | no |
| <a name="input_slack_username"></a> [slack\_username](#input\_slack\_username) | Slack User Name | `string` | `""` | no |
| <a name="input_sms_message_body"></a> [sms\_message\_body](#input\_sms\_message\_body) | n/a | `string` | `"sms_message_body"` | no |
| <a name="input_sns_subscription_email_address_list"></a> [sns\_subscription\_email\_address\_list](#input\_sns\_subscription\_email\_address\_list) | List of email addresses | `list(string)` | <pre>[<br>  "katrin@dasmeta.com"<br>]</pre> | no |
| <a name="input_sns_subscription_phone_number_list"></a> [sns\_subscription\_phone\_number\_list](#input\_sns\_subscription\_phone\_number\_list) | List of telephone numbers to subscribe to SNS. | `list(string)` | <pre>[<br>  "+37499091710"<br>]</pre> | no |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | n/a | `string` | `"Maximum"` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | n/a | `string` | `"200"` | no |
| <a name="input_threshold_type"></a> [threshold\_type](#input\_threshold\_type) | n/a | `string` | `"PERCENTAGE"` | no |
| <a name="input_time_period_end"></a> [time\_period\_end](#input\_time\_period\_end) | n/a | `string` | `"2087-06-15_00:00"` | no |
| <a name="input_time_period_start"></a> [time\_period\_start](#input\_time\_period\_start) | n/a | `string` | `"2022-01-01_00:00"` | no |
| <a name="input_time_unit"></a> [time\_unit](#input\_time\_unit) | n/a | `string` | `"MONTHLY"` | no |

## Outputs

No outputs.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alert_notify_slack"></a> [alert\_notify\_slack](#module\_alert\_notify\_slack) | terraform-aws-modules/notify-slack/aws | 4.18.0 |

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.budget_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_cloudwatch_metric_alarm.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.alerts_notify_email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts_notify_opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.alerts_notify_sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.sms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | n/a | `string` | `"Billing-alarm"` | no |
| <a name="input_budget_type"></a> [budget\_type](#input\_budget\_type) | n/a | `string` | `"COST"` | no |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | n/a | `string` | `"GREATER_THAN"` | no |
| <a name="input_comparison_operator_billing"></a> [comparison\_operator\_billing](#input\_comparison\_operator\_billing) | n/a | `string` | `"GreaterThanOrEqualToThreshold"` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | The access logs format to sync into cloudwatch log group | `string` | `"  { \"http\": { \"defaultHealthyRetryPolicy\": { \"minDelayTarget\": 20, \"maxDelayTarget\": 20, \"numRetries\": 3, \"numMaxDelayRetries\": 0, \"numNoDelayRetries\": 0, \"numMinDelayRetries\": 0,\"backoffFunction\": \"linear\"},\"disableSubscriptionOverrides\": false, \"defaultThrottlePolicy\": { \"maxReceivesPerSecond\": 1 } }}\n"` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `string` | `"1"` | no |
| <a name="input_limit_amount"></a> [limit\_amount](#input\_limit\_amount) | n/a | `string` | `"200"` | no |
| <a name="input_limit_unit"></a> [limit\_unit](#input\_limit\_unit) | n/a | `string` | `"USD"` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | n/a | `string` | `"EstimatedCharges"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"Account-Monthly-Budget"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"Billing"` | no |
| <a name="input_notification_type"></a> [notification\_type](#input\_notification\_type) | n/a | `string` | `"ACTUAL"` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"28800"` | no |
| <a name="input_sns_subscription"></a> [sns\_subscription](#input\_sns\_subscription) | n/a | `map` | <pre>{<br>  "cloudwatch_log_group_retention_in_days": 0,<br>  "opsgenie_endpoint": [<br>    "https://api.opsgenie.com/v1/json/amazonsns?apiKey=5736f9c8-409d-4b67-b922-45926096bf54"<br>  ],<br>  "slack_channel": "",<br>  "slack_username": "",<br>  "slack_webhook_url": "",<br>  "sms_message_body": "sms_message_body",<br>  "sns_subscription_email_address_list": [],<br>  "sns_subscription_phone_number_list": []<br>}</pre> | no |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | n/a | `string` | `"Maximum"` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | n/a | `string` | `"200"` | no |
| <a name="input_threshold_type"></a> [threshold\_type](#input\_threshold\_type) | n/a | `string` | `"PERCENTAGE"` | no |
| <a name="input_time_period_end"></a> [time\_period\_end](#input\_time\_period\_end) | n/a | `string` | `"2087-06-15_00:00"` | no |
| <a name="input_time_period_start"></a> [time\_period\_start](#input\_time\_period\_start) | n/a | `string` | `"2022-01-01_00:00"` | no |
| <a name="input_time_unit"></a> [time\_unit](#input\_time\_unit) | n/a | `string` | `"MONTHLY"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
