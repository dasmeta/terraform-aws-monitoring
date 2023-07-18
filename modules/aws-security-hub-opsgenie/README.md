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
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | 5.2.0 |
| <a name="module_lambda-slack"></a> [lambda-slack](#module\_lambda-slack) | terraform-aws-modules/lambda/aws | 5.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.slack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_event_target.sns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_securityhub_account.sec-hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_action_target.sec-hub-target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_action_target) | resource |
| [aws_securityhub_finding_aggregator.sec-hub-aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_member.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_member) | resource |
| [aws_sns_topic.sns-sec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.sns-to-opsgenie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.sns-to-teams](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [archive_file.lambda_code_zip_slack](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.lambda_code_zip_teams](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.sns_topic_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_slack_target"></a> [create\_slack\_target](#input\_create\_slack\_target) | Create Target for send notification to Slack | `bool` | `false` | no |
| <a name="input_create_sns_target"></a> [create\_sns\_target](#input\_create\_sns\_target) | Create Target for send notification to SNS | `bool` | `false` | no |
| <a name="input_create_teams_target"></a> [create\_teams\_target](#input\_create\_teams\_target) | Create Target for send notification to Teams | `bool` | `false` | no |
| <a name="input_enable_security_hub"></a> [enable\_security\_hub](#input\_enable\_security\_hub) | Whether to enable/activate security hub and its finding aggregator for aws account, this is useful in case the security hub is already enabled (for example when we test, or account have it enable by default) | `bool` | `true` | no |
| <a name="input_enable_security_hub_finding_aggregator"></a> [enable\_security\_hub\_finding\_aggregator](#input\_enable\_security\_hub\_finding\_aggregator) | Whether to enable/create security hub and its finding aggregator for aws account, this is useful in case there is already created security hub finding aggregator | `bool` | `true` | no |
| <a name="input_lambda_environment_variables"></a> [lambda\_environment\_variables](#input\_lambda\_environment\_variables) | Environment variables to pass to Lambda function | `map(any)` | `{}` | no |
| <a name="input_link_mode"></a> [link\_mode](#input\_link\_mode) | n/a | `string` | `"ALL_REGIONS"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name | `string` | n/a | yes |
| <a name="input_securityhub_members"></a> [securityhub\_members](#input\_securityhub\_members) | Security Hub Member Accounts (Email and Account Id) | `map(any)` | `{}` | no |
| <a name="input_sns_email_subscription"></a> [sns\_email\_subscription](#input\_sns\_email\_subscription) | Webhook for sending notification to Email | `string` | `""` | no |
| <a name="input_sns_opsgenie_subscription"></a> [sns\_opsgenie\_subscription](#input\_sns\_opsgenie\_subscription) | Webhook for sending notification to opsgenie | `string` | `""` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
