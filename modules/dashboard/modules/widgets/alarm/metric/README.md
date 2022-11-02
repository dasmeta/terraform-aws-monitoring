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
| <a name="input_alarm_arn"></a> [alarm\_arn](#input\_alarm\_arn) | The aws alarm arn to show metrics | `string` | n/a | yes |
| <a name="input_anomaly_detection"></a> [anomaly\_detection](#input\_anomaly\_detection) | Enables anomaly detection on widget metrics | `bool` | `false` | no |
| <a name="input_coordinates"></a> [coordinates](#input\_coordinates) | position | <pre>object({<br>    x : number<br>    y : number<br>    width : number<br>    height : number<br>  })</pre> | n/a | yes |
| <a name="input_stacked"></a> [stacked](#input\_stacked) | The stacked option for log insights widgets | `bool` | `false` | no |
| <a name="input_title"></a> [title](#input\_title) | n/a | `string` | `null` | no |
| <a name="input_view"></a> [view](#input\_view) | The type of chart to visualization stats data | `string` | `"timeSeries"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data"></a> [data](#output\_data) | n/a |
<!-- END_TF_DOCS -->