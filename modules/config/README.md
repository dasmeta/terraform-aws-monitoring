# AWS Config Module

This module sets up AWS Config, which is **REQUIRED** for AWS Security Hub to work properly.

> **Note**: While this module can be used independently, it is **designed and recommended** to be used through the [security-hub](../security-hub) module as a dependency. The security-hub module provides integrated management of Config along with other security services (Inspector, GuardDuty, Macie) and centralized alerting for all findings.

## Why AWS Config is Required

AWS Security Hub standards rely on AWS Config to evaluate resource configurations. Without AWS Config:
- Security Hub standards cannot evaluate resource configurations
- You won't get accurate findings for networking, IAM, and EC2/EKS misconfigurations
- Security scores won't appear in Security Hub

## ⚠️ Region-Specific Service

**AWS Config is a region-specific service.** This module creates Config resources in the AWS provider's current region only.

- **To enable Config in multiple regions**: Deploy this module separately in each region (using provider aliases or separate Terraform workspaces)
- **Findings aggregation**: When used through the Security Hub module, findings from all regions are automatically aggregated via Security Hub's finding aggregator (`link_mode = "ALL_REGIONS"` or `link_mode = "SPECIFIED_REGIONS"`)
- **Current region**: The module will handle data only in the AWS provider's configured region

## Usage

```hcl
module "config" {
  source  = "dasmeta/monitoring/aws//modules/config"
  # version = "x.y.z"  # It's important to check and set the module version exact when using in real setups to not get accidental auto upgrades

  name = "my-config"

  # Optional: Provide your own S3 bucket
  # s3_bucket_name = "my-config-bucket"

  # Optional: Customize recording
  # record_all_resources = true
  # include_global_resources = true
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 4.0  |

## Inputs

| Name                     | Description                          | Type          | Default              | Required |
| ------------------------ | ------------------------------------ | ------------- | -------------------- | :------: |
| name                     | Name prefix for AWS Config resources | `string`      | n/a                  |   yes    |
| enable                   | Enable AWS Config                    | `bool`        | `true`               |    no    |
| record_all_resources     | Record all supported resource types  | `bool`        | `true`               |    no    |
| include_global_resources | Include global resources (IAM, etc.) | `bool`        | `true`               |    no    |
| s3_bucket_name           | S3 bucket name (empty = auto-create) | `string`      | `""`                 |    no    |
| s3_bucket_force_destroy  | Force destroy S3 bucket              | `bool`        | `false`              |    no    |
| delivery_frequency       | Config snapshot delivery frequency   | `string`      | `"TwentyFour_Hours"` |    no    |
| tags                     | Tags to apply to resources           | `map(string)` | `{}`                 |    no    |

## Outputs

| Name                        | Description                                       |
| --------------------------- | ------------------------------------------------- |
| configuration_recorder_name | The name of the AWS Config configuration recorder |
| configuration_recorder_arn  | The ARN of the AWS Config configuration recorder  |
| delivery_channel_name       | The name of the AWS Config delivery channel       |
| s3_bucket_name              | The name of the S3 bucket used for AWS Config     |
| s3_bucket_arn               | The ARN of the S3 bucket used for AWS Config      |
| iam_role_arn                | The ARN of the IAM role for AWS Config            |
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_config_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_config_rule) | resource |
| [aws_config_configuration_recorder.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_service_linked_role.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [aws_s3_bucket.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_role.config_service_linked_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_service_linked_role"></a> [create\_service\_linked\_role](#input\_create\_service\_linked\_role) | Whether to create the AWS Config service-linked role. Set to false if the role already exists in your account. If set to false and the role doesn't exist, Terraform will fail. If set to true and the role already exists, Terraform will fail with EntityAlreadyExists error - in that case, set this to false and import the existing role: terraform import module.config.aws\_iam\_service\_linked\_role.config aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig | `bool` | `true` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | Frequency for Config snapshot delivery. Valid values: One\_Hour, Three\_Hours, Six\_Hours, Twelve\_Hours, TwentyFour\_Hours | `string` | `"TwentyFour_Hours"` | no |
| <a name="input_excluded_resource_types"></a> [excluded\_resource\_types](#input\_excluded\_resource\_types) | List of resource types to exclude when record\_all\_resources is true. | `list(string)` | `[]` | no |
| <a name="input_include_global_resources"></a> [include\_global\_resources](#input\_include\_global\_resources) | Include global resources (IAM, etc.) in AWS Config recording | `bool` | `true` | no |
| <a name="input_included_resource_types"></a> [included\_resource\_types](#input\_included\_resource\_types) | List of resource types to include when record\_all\_resources is false. If empty and record\_all\_resources is false, all resources are excluded. | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix for AWS Config resources | `string` | n/a | yes |
| <a name="input_record_all_resources"></a> [record\_all\_resources](#input\_record\_all\_resources) | Record all supported resource types in AWS Config | `bool` | `true` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Map of Config rules to create. Key is the rule name. If empty, no rules will be created. | <pre>map(object({<br/>    description = optional(string)<br/>    source = optional(object({<br/>      owner             = string<br/>      source_identifier = string<br/>      source_detail = optional(list(object({<br/>        event_source                = optional(string)<br/>        maximum_execution_frequency = optional(string)<br/>        message_type                = optional(string)<br/>      })))<br/>    }))<br/>    scope = optional(object({<br/>      compliance_resource_types = optional(list(string))<br/>      compliance_resource_id    = optional(string)<br/>      tag_key                   = optional(string)<br/>      tag_value                 = optional(string)<br/>    }))<br/>    input_parameters = optional(string)<br/>    tags             = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_s3_bucket_force_destroy"></a> [s3\_bucket\_force\_destroy](#input\_s3\_bucket\_force\_destroy) | Force destroy S3 bucket for Config when deleting the module | `bool` | `false` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | S3 bucket name for AWS Config. If empty, a bucket will be created automatically. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configuration_recorder_id"></a> [configuration\_recorder\_id](#output\_configuration\_recorder\_id) | The ID of the AWS Config configuration recorder |
| <a name="output_configuration_recorder_name"></a> [configuration\_recorder\_name](#output\_configuration\_recorder\_name) | The name of the AWS Config configuration recorder |
| <a name="output_delivery_channel_name"></a> [delivery\_channel\_name](#output\_delivery\_channel\_name) | The name of the AWS Config delivery channel |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | The ARN of the IAM service-linked role for AWS Config (AWSServiceRoleForConfig) |
| <a name="output_rules"></a> [rules](#output\_rules) | Map of Config rule resources (key is rule name) |
| <a name="output_s3_bucket_arn"></a> [s3\_bucket\_arn](#output\_s3\_bucket\_arn) | The ARN of the S3 bucket used for AWS Config |
| <a name="output_s3_bucket_name"></a> [s3\_bucket\_name](#output\_s3\_bucket\_name) | The name of the S3 bucket used for AWS Config |
| <a name="output_service_linked_role"></a> [service\_linked\_role](#output\_service\_linked\_role) | The AWS Config service-linked role resource (null if using existing role) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
