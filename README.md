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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>4.50 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alerts"></a> [alerts](#module\_alerts) | ./modules/alerts/ | n/a |
| <a name="module_alerts_application_channel"></a> [alerts\_application\_channel](#module\_alerts\_application\_channel) | ./modules/alerts/ | n/a |
| <a name="module_aws_cloudwatch_log_metric_filter"></a> [aws\_cloudwatch\_log\_metric\_filter](#module\_aws\_cloudwatch\_log\_metric\_filter) | dasmeta/modules/aws//modules/cloudwatch-log-metric | 1.7.0 |
| <a name="module_eks_monitoring_dashboard"></a> [eks\_monitoring\_dashboard](#module\_eks\_monitoring\_dashboard) | ./modules/dashboard/ | n/a |
| <a name="module_health-check"></a> [health-check](#module\_health-check) | ./modules/alerts/ | n/a |
| <a name="module_monitoring_dashboard"></a> [monitoring\_dashboard](#module\_monitoring\_dashboard) | ./modules/dashboard/ | n/a |
| <a name="module_sns-to-teams"></a> [sns-to-teams](#module\_sns-to-teams) | ./modules/cloudwatch-alarm-actions/ | n/a |
| <a name="module_sns-to-teams-application-channel"></a> [sns-to-teams-application-channel](#module\_sns-to-teams-application-channel) | ./modules/cloudwatch-alarm-actions/ | n/a |
| <a name="module_sns-to-teams-virginia"></a> [sns-to-teams-virginia](#module\_sns-to-teams-virginia) | ./modules/cloudwatch-alarm-actions/ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Alerts | `any` | `[]` | no |
| <a name="input_application_channel_alerts"></a> [application\_channel\_alerts](#input\_application\_channel\_alerts) | Application channel alerts | `any` | `[]` | no |
| <a name="input_application_channel_webhook_url"></a> [application\_channel\_webhook\_url](#input\_application\_channel\_webhook\_url) | Application Teams Channel Webhook URL | `string` | n/a | yes |
| <a name="input_application_monitroing_dashboard"></a> [application\_monitroing\_dashboard](#input\_application\_monitroing\_dashboard) | Application for monitoring EKS cluster | `any` | `[]` | no |
| <a name="input_create_alerts"></a> [create\_alerts](#input\_create\_alerts) | Create Alert | `bool` | `true` | no |
| <a name="input_create_application_channel"></a> [create\_application\_channel](#input\_create\_application\_channel) | Create application alert | `bool` | `true` | no |
| <a name="input_eks_monitroing_dashboard"></a> [eks\_monitroing\_dashboard](#input\_eks\_monitroing\_dashboard) | Dashboard for monitoring EKS cluster | `any` | `[]` | no |
| <a name="input_enable_log_base_metrics"></a> [enable\_log\_base\_metrics](#input\_enable\_log\_base\_metrics) | n/a | `bool` | `true` | no |
| <a name="input_fallback_email_addresses"></a> [fallback\_email\_addresses](#input\_fallback\_email\_addresses) | List of fallback email addresses to send notification when lambda failed | `list(string)` | `[]` | no |
| <a name="input_fallback_phone_numbers"></a> [fallback\_phone\_numbers](#input\_fallback\_phone\_numbers) | List of international formatted phone number to send notification when lambda failed | `list(string)` | `[]` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Health\_checks endpoints and paths | `any` | `[]` | no |
| <a name="input_log_base_metrics"></a> [log\_base\_metrics](#input\_log\_base\_metrics) | Log Base Metrics | `any` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where resources should be managed. In this repository it's secondary because IAM is always global. | `string` | `"eu-central-1"` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | SNS topic name | `string` | `"cloudwatch-alarm"` | no |
| <a name="input_webhook_url"></a> [webhook\_url](#input\_webhook\_url) | Teams Webhook URL | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
| <a name="output_sns_topic_arn_application_channel"></a> [sns\_topic\_arn\_application\_channel](#output\_sns\_topic\_arn\_application\_channel) | n/a |
| <a name="output_sns_topic_arn_virginia"></a> [sns\_topic\_arn\_virginia](#output\_sns\_topic\_arn\_virginia) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
