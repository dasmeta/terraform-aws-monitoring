## Why
Modules to quickly spin up fully functional of monitoring.
Using pre-commit hooks

## What hooks we use

We use terraform-fmt, terraform-docs, trailing whitespace, detect-aws-credentials, check-merge-conflict, detect-private-key.

## Requirements for pre-commit hooks
for Run our pre-commit hooks you need to install
	- terraform
	- terraform-docs

## Config for GitHooks

```bash
git config core.hooksPath githooks
```


## What
- security-hub
- aws-billing
- eventbridge
- pre-commit hooks
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.50, < 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerts"></a> [alerts](#module\_alerts) | ./modules/alerts/ | n/a |
| <a name="module_alerts_slo_sli_sla"></a> [alerts\_slo\_sli\_sla](#module\_alerts\_slo\_sli\_sla) | ./modules/alerts/ | n/a |
| <a name="module_aws_cloudwatch_log_metric_filter"></a> [aws\_cloudwatch\_log\_metric\_filter](#module\_aws\_cloudwatch\_log\_metric\_filter) | ./modules/cloudwatch-log-based-metrics | n/a |
| <a name="module_eks_monitoring_dashboard"></a> [eks\_monitoring\_dashboard](#module\_eks\_monitoring\_dashboard) | ./modules/dashboard/ | n/a |
| <a name="module_health-check"></a> [health-check](#module\_health-check) | ./modules/alerts/ | n/a |
| <a name="module_monitoring_dashboard"></a> [monitoring\_dashboard](#module\_monitoring\_dashboard) | ./modules/dashboard/ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Alerts | `any` | `[]` | no |
| <a name="input_application_channel_alerts"></a> [application\_channel\_alerts](#input\_application\_channel\_alerts) | Application channel alerts | `any` | `[]` | no |
| <a name="input_application_monitroing_dashboard"></a> [application\_monitroing\_dashboard](#input\_application\_monitroing\_dashboard) | Application for monitoring EKS cluster | `any` | `[]` | no |
| <a name="input_create_alerts"></a> [create\_alerts](#input\_create\_alerts) | Create Alert | `bool` | `true` | no |
| <a name="input_eks_monitroing_dashboard"></a> [eks\_monitroing\_dashboard](#input\_eks\_monitroing\_dashboard) | Dashboard for monitoring EKS cluster | `any` | `[]` | no |
| <a name="input_enable_log_base_metrics"></a> [enable\_log\_base\_metrics](#input\_enable\_log\_base\_metrics) | n/a | `bool` | `true` | no |
| <a name="input_expression_alert"></a> [expression\_alert](#input\_expression\_alert) | Add multiple metrics in one alert and add expression. | `any` | `{}` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Health\_checks endpoints and paths | `any` | `[]` | no |
| <a name="input_log_base_metrics"></a> [log\_base\_metrics](#input\_log\_base\_metrics) | Log Base Metrics creation configuration | <pre>list(object({<br>    name           = string<br>    pattern        = string<br>    log_group_name = string<br>    unit           = optional(string, "None")<br>    dimensions     = optional(any, {})<br>    value          = optional(string, "1")<br>    default_value  = optional(string, "0")<br>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where resources should be managed. In this repository it's secondary because IAM is always global. | `string` | `"eu-central-1"` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | SNS topic name | `string` | `"cloudwatch-alarm"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
