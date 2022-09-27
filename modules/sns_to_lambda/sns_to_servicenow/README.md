# cloudfront-to-s3-to-cloudwatch

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
| <a name="module_lambda"></a> [lambda](#module\_lambda) | raymondbutcher/lambda-builder/aws | 1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_alarm"></a> [create\_alarm](#input\_create\_alarm) | n/a | `bool` | `false` | no |
| <a name="input_envs"></a> [envs](#input\_envs) | n/a | `any` | `{}` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | n/a | `string` | `""` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Memory size for Lambda function | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout for Lambda function | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | n/a |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
