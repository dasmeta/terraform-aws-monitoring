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
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Allow to enable anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | n/a | `string` | n/a | yes |
| <a name="input_container"></a> [container](#input\_container) | n/a | `string` | n/a | yes |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"default"` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END_TF_DOCS -->
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
| <a name="module_container_all_requests"></a> [container\_all\_requests](#module\_container\_all\_requests) | ./modules/widgets/container/all-requests | n/a |
| <a name="module_container_cpu_widget"></a> [container\_cpu\_widget](#module\_container\_cpu\_widget) | ./modules/widgets/container/cpu | n/a |
| <a name="module_container_error_rate"></a> [container\_error\_rate](#module\_container\_error\_rate) | ./modules/widgets/container/error-rate | n/a |
| <a name="module_container_external_health_check_widget"></a> [container\_external\_health\_check\_widget](#module\_container\_external\_health\_check\_widget) | ./modules/widgets/container/external-health-check | n/a |
| <a name="module_container_health_check"></a> [container\_health\_check](#module\_container\_health\_check) | ./modules/widgets/container/health-check | n/a |
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget) | ./modules/widgets/container/memory | n/a |
| <a name="module_container_network_in_widget"></a> [container\_network\_in\_widget](#module\_container\_network\_in\_widget) | ./modules/widgets/container/network-in | n/a |
| <a name="module_container_network_out_widget"></a> [container\_network\_out\_widget](#module\_container\_network\_out\_widget) | ./modules/widgets/container/network-out | n/a |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget) | ./modules/widgets/container/network | n/a |
| <a name="module_container_replicas_widget"></a> [container\_replicas\_widget](#module\_container\_replicas\_widget) | ./modules/widgets/container/replicas | n/a |
| <a name="module_container_request_count_widget"></a> [container\_request\_count\_widget](#module\_container\_request\_count\_widget) | ./modules/widgets/container/request-count | n/a |
| <a name="module_container_response_time_widget"></a> [container\_response\_time\_widget](#module\_container\_response\_time\_widget) | ./modules/widgets/container/response-time | n/a |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget) | ./modules/widgets/container/restarts | n/a |
| <a name="module_dashboard-with-container-metrics"></a> [dashboard-with-container-metrics](#module\_dashboard-with-container-metrics) | ../../.. | n/a |
| <a name="module_text_title"></a> [text\_title](#module\_text\_title) | ./modules/widgets/text/title | n/a |
| <a name="module_text_title_with_link"></a> [text\_title\_with\_link](#module\_text\_title\_with\_link) | ./modules/widgets/text/title-with-link | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Allow to enable anomaly detection on widget metrics | `bool` | `true` | no |
| <a name="input_balancer_name"></a> [balancer\_name](#input\_balancer\_name) | n/a | `string` | `""` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | n/a | `string` | n/a | yes |
| <a name="input_container"></a> [container](#input\_container) | n/a | `string` | n/a | yes |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_healthcheck_id"></a> [healthcheck\_id](#input\_healthcheck\_id) | n/a | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"default"` | no |
| <a name="input_period"></a> [period](#input\_period) | stats | `number` | `60` | no |
| <a name="input_target_group_arn"></a> [target\_group\_arn](#input\_target\_group\_arn) | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
