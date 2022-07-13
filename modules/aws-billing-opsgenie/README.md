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
| [aws_budgets_budget.budget_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |
| [aws_cloudwatch_metric_alarm.billing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_sns_topic.billing_alarm_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.billing_alarm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.billing_alarm_subscribtion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_budget_limit"></a> [account\_budget\_limit](#input\_account\_budget\_limit) | n/a | `string` | `"200"` | no |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | n/a | `string` | `"Das Meta"` | no |
| <a name="input_alarm_name"></a> [alarm\_name](#input\_alarm\_name) | n/a | `string` | `"Billing-alarm"` | no |
| <a name="input_budget_type"></a> [budget\_type](#input\_budget\_type) | n/a | `string` | `"COST"` | no |
| <a name="input_comparison_operator"></a> [comparison\_operator](#input\_comparison\_operator) | n/a | `string` | `"GREATER_THAN"` | no |
| <a name="input_evaluation_periods"></a> [evaluation\_periods](#input\_evaluation\_periods) | n/a | `string` | `"1"` | no |
| <a name="input_limit_unit"></a> [limit\_unit](#input\_limit\_unit) | n/a | `string` | `"USD"` | no |
| <a name="input_metric_name"></a> [metric\_name](#input\_metric\_name) | n/a | `string` | `"EstimatedCharges"` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"account-billing-alarm-topic"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"AWS/Billing"` | no |
| <a name="input_notification_type"></a> [notification\_type](#input\_notification\_type) | n/a | `string` | `"FORECASTED"` | no |
| <a name="input_opsgenie-webhook"></a> [opsgenie-webhook](#input\_opsgenie-webhook) | Webhook for sending notification to opsgenie | `string` | `"https://api.opsgenie.com/v1/json/amazonsns?apiKey=2993a918-f151-4446-aaf5-42cb5f1a255e"` | no |
| <a name="input_period"></a> [period](#input\_period) | n/a | `string` | `"28800"` | no |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | n/a | `string` | `"https"` | no |
| <a name="input_statistic"></a> [statistic](#input\_statistic) | n/a | `string` | `"Maximum"` | no |
| <a name="input_threshold"></a> [threshold](#input\_threshold) | n/a | `string` | `"200"` | no |
| <a name="input_threshold_type"></a> [threshold\_type](#input\_threshold\_type) | n/a | `string` | `"PERCENTAGE"` | no |
| <a name="input_time_unit"></a> [time\_unit](#input\_time\_unit) | n/a | `string` | `"MONTHLY"` | no |

## Outputs

No outputs.