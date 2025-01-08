# combined

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
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_distribution) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br/>    x : number<br/>    y : number<br/>    width : number<br/>    height : number<br/>  })</pre> | n/a | yes |
| <a name="input_distribution"></a> [distribution](#input\_distribution) | n/a | `string` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | stats | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
