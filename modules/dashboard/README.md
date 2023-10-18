<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                    | Version |
| ------------------------------------------------------- | ------- |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.3  |

## Providers

| Name                                                                      | Version |
| ------------------------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws)                         | ~> 4.3  |
| <a name="provider_aws.logging"></a> [aws.logging](#provider\_aws.logging) | ~> 4.3  |

## Modules

| Name                                                                                                                                    | Source                                | Version |
| --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | ------- |
| <a name="module_container_balancer_2xx_widget"></a> [container\_balancer\_2xx\_widget](#module\_container\_balancer\_2xx\_widget)       | ./modules/widgets/balancer/2xx        | n/a     |
| <a name="module_container_balancer_4xx_widget"></a> [container\_balancer\_4xx\_widget](#module\_container\_balancer\_4xx\_widget)       | ./modules/widgets/balancer/4xx        | n/a     |
| <a name="module_container_balancer_5xx_widget"></a> [container\_balancer\_5xx\_widget](#module\_container\_balancer\_5xx\_widget)       | ./modules/widgets/balancer/5xx        | n/a     |
| <a name="module_container_cpu_widget"></a> [container\_cpu\_widget](#module\_container\_cpu\_widget)                                    | ./modules/widgets/container/cpu       | n/a     |
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget)                           | ./modules/widgets/container/memory    | n/a     |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget)                        | ./modules/widgets/container/network   | n/a     |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget)                     | ./modules/widgets/container/restarts  | n/a     |
| <a name="module_text_title"></a> [text\_title](#module\_text\_title)                                                                    | ./modules/widgets/text/title          | n/a     |
| <a name="module_widget_application"></a> [widget\_application](#module\_widget\_application)                                            | ./modules/widgets/application         | n/a     |
| <a name="module_widget_custom"></a> [widget\_custom](#module\_widget\_custom)                                                           | ./modules/widgets/custom              | n/a     |
| <a name="module_widget_log_based"></a> [widget\_log\_based](#module\_widget\_log\_based)                                                | ./modules/widgets/log-based           | n/a     |
| <a name="module_widget_logs_insight_logs"></a> [widget\_logs\_insight\_logs](#module\_widget\_logs\_insight\_logs)                      | ./modules/widgets/logs-insight-logs   | n/a     |
| <a name="module_widget_logs_insight_metric"></a> [widget\_logs\_insight\_metric](#module\_widget\_logs\_insight\_metric)                | ./modules/widgets/logs-insight-metric | n/a     |
| --------------------------------------------------------------------------------------------------------------------------------------- | --------                              |
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource                              |
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)           | data source                           |

## Inputs

| Name                                                       | Description                                                                                                       | Type     | Default | Required |
| ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values to be supplied to all modules.                                                                     | `any`    | `{}`    |    no    |
| <a name="input_name"></a> [name](#input\_name)             | Dashboard name. Should not contain spaces and special chars.                                                      | `string` | n/a     |   yes    |
| <a name="input_rows"></a> [rows](#input\_rows)             | List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets. | `any`    | n/a     |   yes    |

## Outputs

| Name                                             | Description |
| ------------------------------------------------ | ----------- |
| <a name="output_dump"></a> [dump](#output\_dump) | n/a         |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_container_balancer_2xx_widget"></a> [container\_balancer\_2xx\_widget](#module\_container\_balancer\_2xx\_widget) | ./modules/widgets/balancer/2xx | n/a |
| <a name="module_container_balancer_4xx_widget"></a> [container\_balancer\_4xx\_widget](#module\_container\_balancer\_4xx\_widget) | ./modules/widgets/balancer/4xx | n/a |
| <a name="module_container_balancer_5xx_widget"></a> [container\_balancer\_5xx\_widget](#module\_container\_balancer\_5xx\_widget) | ./modules/widgets/balancer/5xx | n/a |
| <a name="module_container_cpu_widget"></a> [container\_cpu\_widget](#module\_container\_cpu\_widget) | ./modules/widgets/container/cpu | n/a |
| <a name="module_container_external_health_check_widget"></a> [container\_external\_health\_check\_widget](#module\_container\_external\_health\_check\_widget) | ./modules/widgets/container/external-health-check | n/a |
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget) | ./modules/widgets/container/memory | n/a |
| <a name="module_container_network_in_widget"></a> [container\_network\_in\_widget](#module\_container\_network\_in\_widget) | ./modules/widgets/container/network-in | n/a |
| <a name="module_container_network_out_widget"></a> [container\_network\_out\_widget](#module\_container\_network\_out\_widget) | ./modules/widgets/container/network-out | n/a |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget) | ./modules/widgets/container/network | n/a |
| <a name="module_container_replicas_widget"></a> [container\_replicas\_widget](#module\_container\_replicas\_widget) | ./modules/widgets/container/replicas | n/a |
| <a name="module_container_request_count_widget"></a> [container\_request\_count\_widget](#module\_container\_request\_count\_widget) | ./modules/widgets/container/request-count | n/a |
| <a name="module_container_response_time_widget"></a> [container\_response\_time\_widget](#module\_container\_response\_time\_widget) | ./modules/widgets/container/response-time | n/a |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget) | ./modules/widgets/container/restarts | n/a |
| <a name="module_text_title"></a> [text\_title](#module\_text\_title) | ./modules/widgets/text/title | n/a |
| <a name="module_widget_alarm_metric"></a> [widget\_alarm\_metric](#module\_widget\_alarm\_metric) | ./modules/widgets/alarm/metric | n/a |
| <a name="module_widget_alarm_status"></a> [widget\_alarm\_status](#module\_widget\_alarm\_status) | ./modules/widgets/alarm/status | n/a |
| <a name="module_widget_application"></a> [widget\_application](#module\_widget\_application) | ./modules/widgets/application | n/a |
| <a name="module_widget_custom"></a> [widget\_custom](#module\_widget\_custom) | ./modules/widgets/custom | n/a |
| <a name="module_widget_logs_insight_logs"></a> [widget\_logs\_insight\_logs](#module\_widget\_logs\_insight\_logs) | ./modules/widgets/logs-insight/logs | n/a |
| <a name="module_widget_logs_insight_metric"></a> [widget\_logs\_insight\_metric](#module\_widget\_logs\_insight\_metric) | ./modules/widgets/logs-insight/metric | n/a |
| <a name="module_widget_rds_cpu"></a> [widget\_rds\_cpu](#module\_widget\_rds\_cpu) | ./modules/widgets/rds/cpu | n/a |
| <a name="module_widget_rds_db_connections"></a> [widget\_rds\_db\_connections](#module\_widget\_rds\_db\_connections) | ./modules/widgets/rds/db-connections | n/a |
| <a name="module_widget_rds_disk"></a> [widget\_rds\_disk](#module\_widget\_rds\_disk) | ./modules/widgets/rds/disk | n/a |
| <a name="module_widget_rds_memory"></a> [widget\_rds\_memory](#module\_widget\_rds\_memory) | ./modules/widgets/rds/memory | n/a |
| <a name="module_widget_sla_slo_sli"></a> [widget\_sla\_slo\_sli](#module\_widget\_sla\_slo\_sli) | ./modules/widgets/sla-slo-sli | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id_as_name_prefix"></a> [account\_id\_as\_name\_prefix](#input\_account\_id\_as\_name\_prefix) | Whether to use aws account id as dashboard name prefix | `bool` | `false` | no |
| <a name="input_data_source_uid"></a> [data\_source\_uid](#input\_data\_source\_uid) | The grafana dashboard widget item data source id, required for only grafana dashboards | `string` | `null` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values to be supplied to all modules. | `any` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name. Should not contain spaces and special chars. | `string` | n/a | yes |
| <a name="input_platform"></a> [platform](#input\_platform) | The platform/service/adapter to create dashboard on. for now only cloudwatch and grafana supported | `string` | `"cloudwatch"` | no |
| <a name="input_rows"></a> [rows](#input\_rows) | List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets. | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dump"></a> [dump](#output\_dump) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
