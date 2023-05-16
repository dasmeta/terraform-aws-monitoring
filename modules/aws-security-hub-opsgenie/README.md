## this module allows to send aws security-hib notifications to opsgenie

# TODO: improve this module(we had several notification channels support including opsgenie) and if possible have it integrated into terraform-aws-account module

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |

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
| <a name="input_enable_security_hub"></a> [enable\_security\_hub](#input\_enable\_security\_hub) | Whether to enable/activate security hub and its finding aggregator for aws account, this is useful in case the security hub is already enabled (for example when we test, or account have it enable by default) | `bool` | `true` | no |
| <a name="input_enable_security_hub_finding_aggregator"></a> [enable\_security\_hub\_finding\_aggregator](#input\_enable\_security\_hub\_finding\_aggregator) | Whether to enable/create security hub and its finding aggregator for aws account, this is useful in case there is already created security hub finding aggregator | `bool` | `true` | no |
| <a name="input_link_mode"></a> [link\_mode](#input\_link\_mode) | n/a | `string` | `"ALL_REGIONS"` | no |
| <a name="input_opsgenie_webhook"></a> [opsgenie\_webhook](#input\_opsgenie\_webhook) | Webhook for sending notification to opsgenie | `string` | n/a | yes |
| <a name="input_protocol"></a> [protocol](#input\_protocol) | n/a | `string` | `"https"` | no |
| <a name="input_securityhub_action_target_name"></a> [securityhub\_action\_target\_name](#input\_securityhub\_action\_target\_name) | n/a | `string` | `"Send-to-SNS"` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Topic name | `string` | `"Send-to-Opsgenie"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
