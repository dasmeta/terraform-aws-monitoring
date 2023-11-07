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
| <a name="module_lambda"></a> [lambda](#module\_lambda) | terraform-aws-modules/lambda/aws | 4.7.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_subscription_filter.subscription_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) | resource |
| [aws_lambda_permission.cloudwatch_permission_to_trigger_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_group_names"></a> [cloudwatch\_log\_group\_names](#input\_cloudwatch\_log\_group\_names) | Cloudwatch Log group name | `list(string)` | n/a | yes |
| <a name="input_lambda_configs"></a> [lambda\_configs](#input\_lambda\_configs) | Lambda Configs | <pre>object({<br>    environment_variables = optional(object({<br>      url = optional(string, "")<br>    }), {})<br>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Lambda name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
