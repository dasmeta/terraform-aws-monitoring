```
module "cloudwatch_metric_filter" {
  source = "dasmeta/modules/aws//modules/metric-filter"

  // Dimensions only applicable for JSON or delimited filter patterns
  metrics_patterns = [
    {
      name    = "ERROR"
      pattern = "ERROR"
      unit    = "None"
      dimensions = {}
    }
  ]
  log_group_name    = "/aws/containerinsights/dasmeta-test-new2/prometheus"
  metrics_namespace = "Log_Filters"
}
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.16 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_metric_filter.metric_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_metric_filter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_log_group_name"></a> [log\_group\_name](#input\_log\_group\_name) | The name of cloudwatch log group on which the metric filters will apply | `string` | n/a | yes |
| <a name="input_metrics_namespace"></a> [metrics\_namespace](#input\_metrics\_namespace) | The namespace of cloudwatch metric | `string` | `"LogBasedMetrics"` | no |
| <a name="input_metrics_patterns"></a> [metrics\_patterns](#input\_metrics\_patterns) | The configurations of log based metric filtration | <pre>list(object({<br>    name       = string<br>    pattern    = string<br>    unit       = optional(string, "None")<br>    dimensions = any<br>  }))</pre> | `[]` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
