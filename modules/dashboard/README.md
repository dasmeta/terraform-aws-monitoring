<!-- BEGIN_TF_DOCS -->
# Example Setup
```tf
module "basic-dashboard-with-text" {
  source = "../../"
  name   = "Basic-Dashboard-with-text"
  rows = [
    [
      {
        type : "text/title"
        text : "Row 1 / col 1"
      }
    ],
    [
      {
        type : "text/title"
        text : "Row 2 / col 1"
      }
    ]
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.3 |

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
| <a name="module_container_memory_widget"></a> [container\_memory\_widget](#module\_container\_memory\_widget) | ./modules/widgets/container/memory | n/a |
| <a name="module_container_network_widget"></a> [container\_network\_widget](#module\_container\_network\_widget) | ./modules/widgets/container/network | n/a |
| <a name="module_container_restarts_widget"></a> [container\_restarts\_widget](#module\_container\_restarts\_widget) | ./modules/widgets/container/restarts | n/a |
| <a name="module_text_title"></a> [text\_title](#module\_text\_title) | ./modules/widgets/text/title | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Default values to be supplied to all modules. | <pre>object(<br>    {<br>      # period      = number<br>      # namespace   = string<br>      # clustername = string<br>      # width       = number<br>      # height      = number<br>    }<br>  )</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Dashboard name. Should not contain spaces and special chars. | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | List of widgets to be inserted into the dashboard. See ./modules/widgets folder to see list of available widgets. | `list(list(any))` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dump"></a> [dump](#output\_dump) | n/a |
<!-- END_TF_DOCS -->
