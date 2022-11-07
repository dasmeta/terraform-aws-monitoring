# graphana-dashboard

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.33 |
| <a name="requirement_grafana"></a> [grafana](#requirement\_grafana) | >= 1.13.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.36.1 |
| <a name="provider_test"></a> [test](#provider\_test) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dashboard-with-logs-insight-metrics-cloudwatch"></a> [dashboard-with-logs-insight-metrics-cloudwatch](#module\_dashboard-with-logs-insight-metrics-cloudwatch) | ../../ | n/a |
| <a name="module_dashboard-with-logs-insight-metrics-grafana"></a> [dashboard-with-logs-insight-metrics-grafana](#module\_dashboard-with-logs-insight-metrics-grafana) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log_group_test_a](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.log_group_test_b](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| test_assertions.api_url | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
