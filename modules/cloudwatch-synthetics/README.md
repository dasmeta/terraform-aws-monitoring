# CloudWatch Synthetics Canaries Module

This public Terraform module creates AWS CloudWatch Synthetics infrastructure.
It does not contain application test behavior, endpoints, protocol parsers,
request templates, or secret values.

## Consumer artifact

Keep each canary ZIP and its test-specific code in the consumer's private
repository or private CI workspace. `script_zip_path` must point to that ZIP
on the machine where Terraform runs. The module uploads it to a private S3
artifact bucket and creates the canary, IAM role, and failure alarm.

The ZIP must be compatible with the selected Synthetics runtime and expose
the fixed handler `canary.handler`. Its code, configuration, and secret-reading
logic remain consumer-owned.

```hcl
module "service_canaries" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-synthetics"
  version = "x.y.z"

  name_prefix   = "example-prod"
  sns_topic_arn = aws_sns_topic.alerts.arn

  canaries = {
    health = {
      script_zip_path = "${path.module}/private-canary.zip"
      secret_arn      = data.aws_secretsmanager_secret.health.arn
    }
  }
}
```

The module uses `CloudWatchSynthetics/Failed` alarms. Set
`artifact_bucket_force_destroy = true` only in an isolated test account.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
CloudWatch Synthetics canaries module.

Provisions generic Synthetics infrastructure for consumer-supplied private ZIPs.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.canary_failed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_iam_role.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_s3_bucket.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_ownership_controls.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.artifacts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.canary_bundle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_synthetics_canary.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/synthetics_canary) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_bucket_force_destroy"></a> [artifact\_bucket\_force\_destroy](#input\_artifact\_bucket\_force\_destroy) | Whether Terraform may delete module-created versioned artifacts; use only for isolated tests. | `bool` | `false` | no |
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | Name of a consumer-owned artifact bucket when create\_artifact\_bucket is false. | `string` | `null` | no |
| <a name="input_artifact_expiration_days"></a> [artifact\_expiration\_days](#input\_artifact\_expiration\_days) | Days to retain current and noncurrent artifact objects. | `number` | `30` | no |
| <a name="input_canaries"></a> [canaries](#input\_canaries) | Map of generic consumer ZIP canary configurations keyed by stable logical name. | <pre>map(object({<br/>    script_zip_path = string<br/>    secret_arn      = string<br/><br/>    schedule        = optional(string, "rate(5 minutes)")<br/>    timeout_seconds = optional(number, 60)<br/>    runtime_version = optional(string, "syn-python-selenium-11.1")<br/>    tags            = optional(map(string), {})<br/><br/>    vpc_config = optional(object({<br/>      subnet_ids         = list(string)<br/>      security_group_ids = list(string)<br/>    }))<br/><br/>    alarm_config = optional(object({<br/>      enabled             = optional(bool, true)<br/>      evaluation_periods  = optional(number, 1)<br/>      datapoints_to_alarm = optional(number, 1)<br/>      period              = optional(number, 60)<br/>      treat_missing_data  = optional(string, "notBreaching")<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_create_artifact_bucket"></a> [create\_artifact\_bucket](#input\_create\_artifact\_bucket) | Whether to create a module-managed S3 bucket for canary artifacts and consumer ZIPs. | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags applied to all taggable module resources. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for artifact encryption and secret decryption. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for generated resource names. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Consumer-owned SNS topic ARN for canary failure alarms. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arns"></a> [alarm\_arns](#output\_alarm\_arns) | Map of canary key to enabled CloudWatch alarm ARN. |
| <a name="output_artifact_bucket_arn"></a> [artifact\_bucket\_arn](#output\_artifact\_bucket\_arn) | ARN of the selected artifact S3 bucket. |
| <a name="output_canary_arns"></a> [canary\_arns](#output\_canary\_arns) | Map of canary key to Synthetics canary ARN. |
| <a name="output_canary_names"></a> [canary\_names](#output\_canary\_names) | Map of canary key to generated Synthetics canary name. |
| <a name="output_execution_role_arns"></a> [execution\_role\_arns](#output\_execution\_role\_arns) | Map of canary key to execution IAM role ARN. |
| <a name="output_script_object_keys"></a> [script\_object\_keys](#output\_script\_object\_keys) | Map of canary key to uploaded consumer ZIP object key. |
| <a name="output_script_object_version_ids"></a> [script\_object\_version\_ids](#output\_script\_object\_version\_ids) | Map of canary key to uploaded consumer ZIP object version ID. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
