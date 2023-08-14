# health_checks

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.59 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | >= 4.59 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_external_health_check-alarms"></a> [external\_health\_check-alarms](#module\_external\_health\_check-alarms) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 4.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_health_check.health_checks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_health_check) | resource |
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Allows to create route53 health checks and alarms on them | `list(any)` | `[]` | no |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | The name of aws sns topic use as target for alarm actions | `string` | `"cloudwatch-alerts"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
