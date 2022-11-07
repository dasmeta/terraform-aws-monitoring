<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_base"></a> [base](#module\_base) | ../base | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | `null` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_metrics"></a> [metrics](#input\_metrics) | n/a | `list(any)` | n/a | yes |
| <a name="input_period"></a> [period](#input\_period) | n/a | `number` | `300` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |

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
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Enables anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_data_source_uid"></a> [data\_source\_uid](#input\_data\_source\_uid) | The grafana dashboard widget item data source id | `string` | n/a | yes |
| <a name="input_platform"></a> [platform](#input\_platform) | The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported | `string` | `"cloudwatch"` | no |
| <a name="input_query"></a> [query](#input\_query) | The Logs Insights query | `string` | n/a | yes |
| <a name="input_sources"></a> [sources](#input\_sources) | The list of log group paths | `list(string)` | n/a | yes |
| <a name="input_stacked"></a> [stacked](#input\_stacked) | The stacked option for log insights widgets | `bool` | `false` | no |
| <a name="input_stats"></a> [stats](#input\_stats) | The stats body for visualization | `list(string)` | n/a | yes |
| <a name="input_time_period"></a> [time\_period](#input\_time\_period) | The time period used as argument in function bin() to group the returned results by a time period, examples: '5m', '30s', '1h' | `string` | `"5m"` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | n/a | yes |
| <a name="input_view"></a> [view](#input\_view) | The type of chart to visualization stats data | `string` | `"timeSeries"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
