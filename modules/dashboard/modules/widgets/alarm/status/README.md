<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_alarm_arns"></a> [alarm\_arns](#input\_alarm\_arns) | The list of aws alarms to show status | `list(string)` | n/a | yes |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Enables anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `300` | no |
| <a name="input_stacked"></a> [stacked](#input\_stacked) | The stacked option for log insights widgets | `bool` | `false` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | There are two type of visualizations of alarms on dashboard: 'alarm' - displays only current status, 'metric' - shows chart with metric of alarm | `string` | `"alarm"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_alarm_arns"></a> [alarm\_arns](#input\_alarm\_arns) | The list of aws alarms to show status | `list(string)` | n/a | yes |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Enables anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `300` | no |
| <a name="input_stacked"></a> [stacked](#input\_stacked) | The stacked option for log insights widgets | `bool` | `false` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |
| <a name="input_type"></a> [type](#input\_type) | There are two type of visualizations of alarms on dashboard: 'alarm' - displays only current status, 'metric' - shows chart with metric of alarm | `string` | `"alarm"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
