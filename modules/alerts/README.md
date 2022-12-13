Module use examples.

# Watch for
```
module "alerts" {
  source = "dasmeta/monitoring/aws//modules/alerts"

  alerts = [
    {
      name: Container has too many restarts
      source: ContainerInsights/pod_number_of_container_restarts
      filters: {
        PodName: "cert-manager",
        ClusterName: "sandbox",
        Namespace: "cert-manager"
      }
      statistic: sum
      equation: gte
      threshold: 1
      period: 300
    },
    {
      name: Too many logs with this message
      source: "LogBasedMetrics/Container 404"
      filters: {}
      statistic: sum
      equation: gte
      threshold: 640
      period: 300
    }
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.16 |
| <a name="provider_aws.logging"></a> [aws.logging](#provider\_aws.logging) | >= 4.16 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_log-based-metric-alarm"></a> [cloudwatch\_log-based-metric-alarm](#module\_cloudwatch\_log-based-metric-alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_cloudwatch_metric-alarm"></a> [cloudwatch\_metric-alarm](#module\_cloudwatch\_metric-alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_cloudwatch_metric-alarm_with_anomalydetection"></a> [cloudwatch\_metric-alarm\_with\_anomalydetection](#module\_cloudwatch\_metric-alarm\_with\_anomalydetection) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_external_health_check-alarms"></a> [external\_health\_check-alarms](#module\_external\_health\_check-alarms) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_health_check.health_checks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_health_check) | resource |
| [aws_caller_identity.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_region.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Allows to create standard and log based metric alarms | <pre>list(object({<br>    name               = string<br>    source             = string<br>    filters            = map(any)<br>    statistic          = string<br>    equation           = string<br>    threshold          = number<br>    period             = number<br>    treat_missing_data = string<br>    log_based_metric   = bool<br>    anomaly_detection  = bool<br>    account_id         = optional(string, null)<br>  }))</pre> | `[]` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Allows to create route53 health checks and alarms on them | `list(any)` | `[]` | no |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | The name of aws sns topic use as target for alarm actions | `string` | `"cloudwatch-alerts"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_data"></a> [alert\_data](#output\_alert\_data) | n/a |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.16 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloudwatch_log-based-metric-alarm"></a> [cloudwatch\_log-based-metric-alarm](#module\_cloudwatch\_log-based-metric-alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_cloudwatch_metric-alarm"></a> [cloudwatch\_metric-alarm](#module\_cloudwatch\_metric-alarm) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_cloudwatch_metric-alarm_with_anomalydetection"></a> [cloudwatch\_metric-alarm\_with\_anomalydetection](#module\_cloudwatch\_metric-alarm\_with\_anomalydetection) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |
| <a name="module_external_health_check-alarms"></a> [external\_health\_check-alarms](#module\_external\_health\_check-alarms) | terraform-aws-modules/cloudwatch/aws//modules/metric-alarm | 3.3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route53_health_check.health_checks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_health_check) | resource |
| [aws_caller_identity.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.project](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alerts"></a> [alerts](#input\_alerts) | Allows to create standard and log based metric alarms | <pre>list(object({<br>    name               = string<br>    source             = string<br>    filters            = map(any)<br>    statistic          = optional(string, "sum")<br>    equation           = optional(string, "gte")<br>    threshold          = optional(number, 1)<br>    period             = optional(number, 300)<br>    treat_missing_data = optional(string, null)<br>    log_based_metric   = optional(bool, false)<br>    anomaly_detection  = optional(bool, false)<br>    account_id         = optional(string, null)<br>  }))</pre> | `[]` | no |
| <a name="input_health_checks"></a> [health\_checks](#input\_health\_checks) | Allows to create route53 health checks and alarms on them | `list(any)` | `[]` | no |
| <a name="input_sns_topic"></a> [sns\_topic](#input\_sns\_topic) | The name of aws sns topic use as target for alarm actions | `string` | `"cloudwatch-alerts"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alert_data"></a> [alert\_data](#output\_alert\_data) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
