<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_metric_filter_test"></a> [cloudwatch\_metric\_filter\_test](#module\_cloudwatch\_metric\_filter\_test) | ../../../cloudwatch-log-based-metrics | n/a |
| <a name="module_dashboard-with-log-based-metrics"></a> [dashboard-with-log-based-metrics](#module\_dashboard-with-log-based-metrics) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log_group_test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
