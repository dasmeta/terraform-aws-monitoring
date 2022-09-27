# Create Lambda for trasfer alert data in to servicenow. SNS topic and lambda subscriptions. You can create alert and send data to created sns.

```
module "sns_to_servicenow" {
  source     = "dasmeta/monitoring/aws//modules/sns_to_servicenow"
  name       = "sns"
  topic_name = "sns_to_servicenow"
  lambda_envs = {
    SERVICENOW_AUTH   = ""
    SERVICENOW_DOMAIN = ""
    SERVICENOW_PATH   = ""
  }
}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.16 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sns_to_servicenow"></a> [sns\_to\_servicenow](#module\_sns\_to\_servicenow) | ./sns_to_servicenow | n/a |
| <a name="module_subscriptions"></a> [subscriptions](#module\_subscriptions) | dasmeta/sns/aws//modules//subscription | 1.2.3 |
| <a name="module_topic"></a> [topic](#module\_topic) | dasmeta/sns/aws//modules/topic | 1.2.3 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_envs"></a> [lambda\_envs](#input\_lambda\_envs) | n/a | `any` | <pre>{<br>  "SERVICENOW_AUTH": "",<br>  "SERVICENOW_DOMAIN": "",<br>  "SERVICENOW_PATH": ""<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"test"` | no |
| <a name="input_topic_name"></a> [topic\_name](#input\_topic\_name) | n/a | `string` | `"test_topic"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
<!-- END_TF_DOCS -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.16 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.16 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sns_to_servicenow"></a> [sns\_to\_servicenow](#module\_sns\_to\_servicenow) | ./sns_to_servicenow | n/a |
| <a name="module_subscriptions"></a> [subscriptions](#module\_subscriptions) | dasmeta/sns/aws//modules//subscription | 1.2.3 |
| <a name="module_topic"></a> [topic](#module\_topic) | dasmeta/sns/aws//modules/topic | 1.2.3 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_envs"></a> [lambda\_envs](#input\_lambda\_envs) | n/a | `any` | <pre>{<br>  "SERVICENOW_AUTH": "",<br>  "SERVICENOW_DOMAIN": "",<br>  "SERVICENOW_PATH": ""<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"test"` | no |
| <a name="input_topic_name"></a> [topic\_name](#input\_topic\_name) | n/a | `string` | `"test_topic"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | n/a |
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
