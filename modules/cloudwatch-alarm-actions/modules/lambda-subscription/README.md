# cloudfront-to-s3-to-cloudwatch

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerts"></a> [alerts](#module\_alerts) | dasmeta/monitoring/aws//modules/alerts | 1.3.4 |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | 4.7.1 |
| <a name="module_subscription"></a> [subscription](#module\_subscription) | dasmeta/sns/aws//modules//subscription | 1.2.3 |

## Resources

| Name | Type |
|------|------|
| [archive_file.lambda_code_zip](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_script_files"></a> [additional\_script\_files](#input\_additional\_script\_files) | List of additional files to include into lambda function zip to upload to aws | `list(string)` | `[]` | no |
| <a name="input_attach_dead_letter_policy"></a> [attach\_dead\_letter\_policy](#input\_attach\_dead\_letter\_policy) | Whether to attach dead letter queue | `bool` | `false` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Whether to create lambda role or not | `bool` | `true` | no |
| <a name="input_dead_letter_queue_arn"></a> [dead\_letter\_queue\_arn](#input\_dead\_letter\_queue\_arn) | The SQS queue arn for using as dead letter | `string` | `null` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables to pass to function | `map(any)` | `{}` | no |
| <a name="input_fallback_sns_topic_name"></a> [fallback\_sns\_topic\_name](#input\_fallback\_sns\_topic\_name) | The fallback sns topic name to attach/create subscription | `string` | n/a | yes |
| <a name="input_lambda_failed_alert"></a> [lambda\_failed\_alert](#input\_lambda\_failed\_alert) | Alert for lambda failed | `any` | <pre>{<br>  "equation": "gte",<br>  "period": 60,<br>  "statistic": "sum",<br>  "threshold": 1<br>}</pre> | no |
| <a name="input_log_group_retention_days"></a> [log\_group\_retention\_days](#input\_log\_group\_retention\_days) | The retention days for cloudwatch log group | `number` | `7` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Memory size for Lambda function | `number` | `null` | no |
| <a name="input_recreate_missing_package"></a> [recreate\_missing\_package](#input\_recreate\_missing\_package) | Whether to recreate missing Lambda package if it is missing locally or not | `bool` | `true` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | In case if we have already created role for function we can pass it | `string` | `null` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | The sns topic name to attach/create subscription | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout for Lambda function | `number` | `null` | no |
| <a name="input_type"></a> [type](#input\_type) | Predefined lambda type | `string` | `"empty"` | no |
| <a name="input_uniq_id"></a> [uniq\_id](#input\_uniq\_id) | Unique string to set as prefix on lambda function name | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
