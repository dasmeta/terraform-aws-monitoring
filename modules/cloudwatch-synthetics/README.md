# CloudWatch Synthetics Canaries Module

This public Terraform module creates AWS CloudWatch Synthetics infrastructure.
It does not contain application test behavior, endpoints, protocol parsers,
request templates, or secret values.

## Consumer source files

Keep each canary's private Python code in the consumer configuration repository.
Give the module a map of ZIP destination paths to source paths relative to the
consumer Terraform root. Terraform builds the ZIP automatically, uploads it to
a private S3 artifact bucket, and creates the canary, IAM role, and failure
alarm. No manual `zip` command is required.

Every source map must include `python/canary.py`. That file must define
`handler(event, context)`. The module fixes the Synthetics runtime to
`syn-python-selenium-11.1` and handler to `canary.handler`.

The module generates root-level `config.json` from the non-secret `config` map
and, when set, the module-owned `secret_name` field. CloudWatch Synthetics
unpacks the ZIP as a Lambda layer, so consumer code reads that file at
`/opt/config.json`. Source files must be UTF-8 text; Terraform's `file()`
function cannot package binary content. Do not put passwords, tokens, or other
secret values in `config`: Terraform state can contain package source content.
Restrict state access to people permitted to read the private code. Source
symlinks are unsupported because Terraform cannot verify their targets remain
inside the consumer workspace. `secret_name` is optional; omit it when the
canary does not read a Secrets Manager secret.

```hcl
module "service_canaries" {
  source  = "dasmeta/monitoring/aws//modules/cloudwatch-synthetics"
  version = "x.y.z"

  name_prefix    = "example-prod"
  sns_topic_name = "example-synthetics-alerts"

  canaries = {
    health = {
      secret_name = "monitoring/example/health"
      source_files = {
        "python/canary.py" = "canaries/health/canary.py"
      }
      config = {
        environment = "production"
      }
    }
  }
}
```

The secret, when provided, must already exist. Terraform looks it up by name
and grants the canary runtime permission to call `GetSecretValue`. The Python
script retrieves the secret value at runtime; Terraform never reads the value.

## DasMeta wrapper example

```yaml
source: dasmeta/monitoring/aws//modules/cloudwatch-synthetics
version: x.y.z
variables:
  name_prefix: example-prod
  sns_topic_name: example-synthetics-alerts
  canaries:
    health:
      secret_name: ${0-accounts/production/monitoring-secrets.health_secret_name}
      source_files:
        python/canary.py: canaries/health/canary.py
      config:
        environment: production
```

`health_secret_name` is a Terraform Cloud output containing the existing AWS
secret name, not an ARN and not a secret value.

The module uses `CloudWatchSynthetics/Failed` alarms. Set
`artifact_bucket_force_destroy = true` only in an isolated test account.
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
CloudWatch Synthetics canaries module.

Provisions generic Synthetics infrastructure for consumer-supplied private source files.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.1 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.64.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [archive_file.canary_bundle](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/resources/file) | resource |
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
| [aws_kms_key.secret_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_sns_topic.alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sns_topic) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_bucket_force_destroy"></a> [artifact\_bucket\_force\_destroy](#input\_artifact\_bucket\_force\_destroy) | Whether Terraform may delete module-created versioned artifacts; use only for isolated tests. | `bool` | `false` | no |
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | Artifact bucket name. Overrides the generated name when create\_artifact\_bucket is true; names the existing bucket when create\_artifact\_bucket is false. | `string` | `null` | no |
| <a name="input_artifact_expiration_days"></a> [artifact\_expiration\_days](#input\_artifact\_expiration\_days) | Days to retain current and noncurrent canary run artifacts under the canaries/ prefix. Source packages under scripts/ are not expired. | `number` | `30` | no |
| <a name="input_canaries"></a> [canaries](#input\_canaries) | Map of generic canary configurations keyed by stable logical name. Source files are relative to the consumer Terraform root; source symlinks are unsupported. secret\_name is optional when the canary does not read Secrets Manager. memory\_in\_mb must be 960-3008 and a multiple of 64. | <pre>map(object({<br/>    source_files = map(string)<br/>    secret_name  = optional(string)<br/>    config       = optional(map(string), {})<br/><br/>    schedule        = optional(string, "rate(5 minutes)")<br/>    timeout_seconds = optional(number, 60)<br/>    memory_in_mb    = optional(number, 960)<br/>    tags            = optional(map(string), {})<br/><br/>    vpc_config = optional(object({<br/>      subnet_ids         = list(string)<br/>      security_group_ids = list(string)<br/>    }))<br/><br/>    alarm_config = optional(object({<br/>      enabled             = optional(bool, true)<br/>      evaluation_periods  = optional(number, 1)<br/>      datapoints_to_alarm = optional(number, 1)<br/>      period              = optional(number, 60)<br/>      treat_missing_data  = optional(string, "notBreaching")<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_create_artifact_bucket"></a> [create\_artifact\_bucket](#input\_create\_artifact\_bucket) | Whether to create a module-managed S3 bucket. When true, artifact\_bucket\_name optionally overrides the generated name. When false, artifact\_bucket\_name is required. | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags applied to all taggable module resources. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for artifact bucket encryption. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for generated resource names. | `string` | n/a | yes |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | Existing SNS topic name for canary failure alarms. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arns"></a> [alarm\_arns](#output\_alarm\_arns) | Map of canary key to enabled CloudWatch alarm ARN. |
| <a name="output_artifact_bucket_arn"></a> [artifact\_bucket\_arn](#output\_artifact\_bucket\_arn) | ARN of the selected artifact S3 bucket. |
| <a name="output_canary_arns"></a> [canary\_arns](#output\_canary\_arns) | Map of canary key to Synthetics canary ARN. |
| <a name="output_canary_names"></a> [canary\_names](#output\_canary\_names) | Map of canary key to generated Synthetics canary name. |
| <a name="output_execution_role_arns"></a> [execution\_role\_arns](#output\_execution\_role\_arns) | Map of canary key to execution IAM role ARN. |
| <a name="output_script_object_keys"></a> [script\_object\_keys](#output\_script\_object\_keys) | Map of canary key to uploaded module-built source package object key. |
| <a name="output_script_object_version_ids"></a> [script\_object\_version\_ids](#output\_script\_object\_version\_ids) | Map of canary key to uploaded module-built source package object version ID. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
