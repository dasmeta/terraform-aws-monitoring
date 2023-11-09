# sqs

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | ALB name | `string` | n/a | yes |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | EKS cluster name | `string` | n/a | yes |
| <a name="input_healthcheck_id"></a> [healthcheck\_id](#input\_healthcheck\_id) | R53 healthcheck ID for the service | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | EKS namespace name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Service nameD | `string` | n/a | yes |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | Target group ARN which points to the service | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | description |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
