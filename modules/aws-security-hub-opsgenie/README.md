## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |
| <a name="requirement_opsgenie"></a> [opsgenie](#requirement\_opsgenie) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_securityhub_account.sec-hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_action_target.sec-hub-target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_action_target) | resource |
| [aws_securityhub_finding_aggregator.sec-hub-aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_sns_topic.sns-sec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.sns-sec-sub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_link-mode"></a> [link-mode](#input\_link-mode) | n/a | `string` | `"ALL_REGIONS"` | no |
| <a name="input_opsgenie-webhook"></a> [opsgenie-webhook](#input\_opsgenie-webhook) | Webhook for sending notification to opsgenie | `string` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | n/a | `string` | `"https"` | no |
| <a name="input_securityhub-name"></a> [securityhub-name](#input\_securityhub-name) | n/a | `string` | `"Send-to-SNS"` | no |
| <a name="input_sns-topic-name"></a> [sns-topic-name](#input\_sns-topic-name) | Topic name | `string` | `"Send-to-Opsgenie"` | no |

## Outputs

No outputs.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |
| <a name="requirement_opsgenie"></a> [opsgenie](#requirement\_opsgenie) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_securityhub_account.sec-hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_action_target.sec-hub-target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_action_target) | resource |
| [aws_securityhub_finding_aggregator.sec-hub-aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_sns_topic.sns-sec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.sns-sec-sub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_link-mode"></a> [link-mode](#input\_link-mode) | n/a | `string` | `"ALL_REGIONS"` | no |
| <a name="input_opsgenie-webhook"></a> [opsgenie-webhook](#input\_opsgenie-webhook) | Webhook for sending notification to opsgenie | `string` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | n/a | `string` | `"https"` | no |
| <a name="input_securityhub-name"></a> [securityhub-name](#input\_securityhub-name) | n/a | `string` | `"Send-to-SNS"` | no |
| <a name="input_sns-topic-name"></a> [sns-topic-name](#input\_sns-topic-name) | Topic name | `string` | `"Send-to-Opsgenie"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
