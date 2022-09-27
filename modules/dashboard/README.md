# AWS CloudWatch Dashboard

Terraform module which create cloudwatch dashboard

## Usage

```
module "dashboard" {
  //  source = "dasmeta/monitoring/aws//modules/dashboard"
  source = "../../"

  name = "Dashboard_name"

  defaults = {
    period : 300
    namespace : "default"
    clustername : "dasmeta-test-new3"
    width : 6
    height : 5
  }

  rows = [
    [
      // ROW1
      {
        type : "text",
        name : "Nginx"
      }
    ],
    // ROW2
    [
      {
        type : "container/cpu",
        period : 300,
        container : "nginx",
      },
      {
        type : "traffic/2xx"
        loadbalancer : "app/fa5487/cd9b9f"
      }
    ]
  ]
}

```


## Examples

- [Minimum](./examples/minimum): Minimum settings for each widget (contains all types of widgets)
- [Maximum](./examples/maximum): Maximum settings for each widget (contains all types of widgets)
- [Randome](./examples/random): Random rows and setting for widgets


## Widget types

When we want create widgets , we can use some defined types.

#### Text widgets
```
      {
        type : "text",
        content : "Nginx"
      }
```

#### Container/Inside metrics types( container/cpu, "container/memory", "container/restarts", "container/network" )

##### Min
```
      {
        type : "container/cpu",
        container : "nginx",
      }
```
##### Max
```
      {
        type : "container/cpu",
        container : "nginx",
        clustername: "dasmeta-test-new3"
        namespace: "default"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region: ""
      }
```

#### ALB/ELB metrics types( "traffic/5xx",  "traffic/4xx", "traffic/3xx")

##### Min
```
      {
        type : "traffic/5xx"
        loadbalancer : "app/fa5487/cd9b9f"
      },
```

##### Max
```
      {
        type : "traffic/5xx"
        loadbalancer : "app/fa5487/cd9b9f"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: "Sum"
        region: ""
      }
```

#### Application Base Metrics if you use Prometheus metrics( "application")

##### Min
```
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        container : "rpc-app-cont"
      }
```


##### Max (If  app name different from container name)
```
      {
        type : "application"
        metric_name : "go_memstats_mallocs_total"
        app : "rpc-app"
        container : "rpc-app-cont"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region: ""
      }
```

#### Log Base Metrics types ("log_base")

##### Min

```
      {
        type: "log_base"
        custom_namespaces: "LogInside"
        metric_name: "CloudTrail"
      }
```

##### Max

```
      {
        type: "log_base"
        custom_namespaces: "LogInside"
        metric_name: "CloudTrail"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region: ""
      }
```

#### Custom Metrics types ("custom")

##### Min
```
      {
        type: "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
      }
```

##### Max

```
      {
        type: "custom"
        source : "AWS/EC2//EBSWriteOps//ImageId//ami-0f2b7c6874eb8414f"
        name: "Widget name"
        width: 6
        height: 5
        period: 300
        statistic: ""
        region: ""
      }
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_all_widget"></a> [all\_widget](#module\_all\_widget) | ./modules/widget/custom | n/a |
| <a name="module_splite_config"></a> [splite\_config](#module\_splite\_config) | ./modules/splite_config | n/a |
| <a name="module_text"></a> [text](#module\_text) | ./modules/widget/text | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_defaults"></a> [defaults](#input\_defaults) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_merged_config"></a> [merged\_config](#output\_merged\_config) | n/a |
| <a name="output_traffic_2xx"></a> [traffic\_2xx](#output\_traffic\_2xx) | n/a |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_all_widget"></a> [all\_widget](#module\_all\_widget) | ./modules/widget/custom | n/a |
| <a name="module_splite_config"></a> [splite\_config](#module\_splite\_config) | ./modules/splite_config | n/a |
| <a name="module_text"></a> [text](#module\_text) | ./modules/widget/text | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_dashboard.dashboards](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_dashboard) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_defaults"></a> [defaults](#input\_defaults) | n/a | `any` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_rows"></a> [rows](#input\_rows) | n/a | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_merged_config"></a> [merged\_config](#output\_merged\_config) | n/a |
| <a name="output_traffic_2xx"></a> [traffic\_2xx](#output\_traffic\_2xx) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
