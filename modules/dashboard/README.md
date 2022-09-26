# AWS CloudWatch Dashboard

Terraform module which create cloudwatch dashboard


## Examples

- [Dashbord-description-with-local](https://github.com/dasmeta/terraform-aws-monitoring/dashboard/examples/complete-with-local):
- [Dashbord-description-with-yaml](https://github.com/dasmeta/terraform-aws-monitoring/dashboard/examples/complete-with-yaml):


<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_all_widget"></a> [all\_widget](#module\_all\_widget) | ./modules/widget/custom | n/a |
| <a name="module_splite_config"></a> [splite\_config](#module\_splite\_config) | ./modules/splite_config | n/a |
| <a name="module_text"></a> [text](#module\_text) | ./modules/widget/text | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_defaults"></a> [defaults](#input\_defaults) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_merged_config"></a> [merged\_config](#output\_merged\_config) | n/a |
| <a name="output_traffic_2xx"></a> [traffic\_2xx](#output\_traffic\_2xx) | n/a |
<!-- END_TF_DOCS -->
