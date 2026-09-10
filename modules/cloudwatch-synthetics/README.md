# CloudWatch Synthetics Canaries Module

Terraform submodule that provisions AWS CloudWatch Synthetics canaries from a grouped `canaries` map. Each entry creates a canary, IAM role, log group, CloudWatch alarm, and shares module-managed S3 artifact storage.

The consuming configuration supplies its own endpoint URLs and Secrets Manager ARNs. This module contains no service hostnames or secret values.

**Source**: `dasmeta/monitoring/aws//modules/cloudwatch-synthetics`

## Supported check types

| check_type | Description |
|------------|-------------|
| `soap_wsdl` | WSDL availability check |
| `soap_cardinfo` | SOAP CardInfo endpoint health (requires `environment.SOAP_NAMESPACE`; if set, `SOAP_VERSION` must match that namespace's SOAP contract) |
| `rest_cardinfo` | REST CardInfo endpoint health |
| `blackhawk_management` | Management API health |

> SOAP CardInfo supports `SOAP_VERSION` v0–v3 via `environment`.

## Example

```hcl
module "service_canaries" {
  source = "dasmeta/monitoring/aws//modules/cloudwatch-synthetics"

  name_prefix   = "service-prod"
  sns_topic_arn = var.sns_topic_arn

  canaries = {
    soap-wsdl-check = {
      check_type   = "soap_wsdl"
      endpoint_url = var.wsdl_endpoint_url
      secret_arn   = var.wsdl_secret_arn
    }

    rest-cardinfo-check = {
      check_type   = "rest_cardinfo"
      endpoint_url = var.rest_cardinfo_endpoint_url
      secret_arn   = var.rest_cardinfo_secret_arn
      secret_fields = {
        CHECK_SETTING = "stored_setting"
      }
      schedule = "rate(5 minutes)"
    }
  }

  default_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Secret handling

Create a JSON secret in AWS Secrets Manager for each canary and pass only its ARN in `secret_arn`. At run time, the canary reads the JSON directly from Secrets Manager.

- Do not put secret values in Terraform variables, code, plans, or this README.
- The secret schema is determined by the selected `check_type` and its target integration.
- Put non-secret settings in `environment`, for example:

```hcl
environment = {
  SOAP_VERSION   = "v3"
  SOAP_NAMESPACE = "https://service.example/soap/v3"
  SOAP_DEVICE_ID = "service-device-id"
  SOAP_OPERATOR_ID = "service-operator-id"
  REQUEST_ID_PREFIX = "service-monitoring"
}
```

### `secret_fields`

Use `secret_fields` only when the key names in your secret differ from the names expected by the check script:

```hcl
secret_fields = {
  CHECK_SETTING = "stored_setting"
}
```

An unauthenticated check can reference an empty JSON secret (`{}`). Secret values are fetched at runtime and redacted from failures by the shared Python helpers.

## VPC opt-in

```hcl
vpc_config = {
  subnet_ids         = ["subnet-abc123"]
  security_group_ids = ["sg-abc123"]
}
```

Ensure egress TCP 443 to the endpoint, Secrets Manager, S3, and CloudWatch Logs (NAT or VPC endpoints).

## Alarm defaults

- Metric: `CloudWatchSynthetics` / `Success` / dimension `CanaryName`
- Comparison: `LessThanThreshold`, threshold `1`
- Evaluation periods: `1`, missing data: `breaching`
- SNS topic is consumer-owned; module wires `sns_topic_arn` as alarm action only

## External artifact bucket

Set `create_artifact_bucket = false` and supply `artifact_bucket_name`. Preflight requirements:

- Bucket exists in the provider region
- Block public access enabled
- Versioning enabled
- TLS-only bucket policy recommended
- Encryption configured (SSE-S3 or SSE-KMS)

## Tests

```bash
cd tests/basic && terraform init && terraform test
```

See [tests/README.md](./tests/README.md) for all scenarios.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
CloudWatch Synthetics canaries module.

Provisions Synthetics canaries from a grouped canaries map with per-canary IAM,
log groups, alarms, and shared S3 artifact storage.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | 2.8.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.canary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
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
| [archive_file.canary_bundle](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_artifact_bucket_name"></a> [artifact\_bucket\_name](#input\_artifact\_bucket\_name) | Name of an existing S3 bucket for artifacts when create\_artifact\_bucket is false. | `string` | `null` | no |
| <a name="input_artifact_expiration_days"></a> [artifact\_expiration\_days](#input\_artifact\_expiration\_days) | S3 lifecycle expiration in days for canary artifact objects. | `number` | `30` | no |
| <a name="input_canaries"></a> [canaries](#input\_canaries) | Map of canary configurations keyed by stable logical name. | <pre>map(object({<br/>    check_type   = string<br/>    endpoint_url = string<br/>    secret_arn   = string<br/><br/>    schedule        = optional(string, "rate(1 minute)")<br/>    timeout_seconds = optional(number, 60)<br/>    retries         = optional(number, 0)<br/>    runtime_version = optional(string, "syn-python-selenium-11.1")<br/>    secret_fields   = optional(map(string), {})<br/>    environment     = optional(map(string), {})<br/>    tags            = optional(map(string), {})<br/><br/>    vpc_config = optional(object({<br/>      subnet_ids         = list(string)<br/>      security_group_ids = list(string)<br/>    }))<br/><br/>    alarm_config = optional(object({<br/>      enabled             = optional(bool, true)<br/>      threshold           = optional(number, 1)<br/>      evaluation_periods  = optional(number, 1)<br/>      datapoints_to_alarm = optional(number, 1)<br/>      period              = optional(number, 60)<br/>      treat_missing_data  = optional(string, "breaching")<br/>      comparison_operator = optional(string, "LessThanThreshold")<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_create_artifact_bucket"></a> [create\_artifact\_bucket](#input\_create\_artifact\_bucket) | Whether to create a module-managed S3 bucket for canary artifacts and script bundles. | `bool` | `true` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Tags applied to all taggable module resources. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Optional KMS key ARN for S3 SSE-KMS encryption and Secrets Manager decrypt. | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch log retention in days for canary log groups. | `number` | `14` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for generated resource names. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | Consumer-owned SNS topic ARN for canary failure alarms. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alarm_arns"></a> [alarm\_arns](#output\_alarm\_arns) | Map of canary key to CloudWatch alarm ARN. |
| <a name="output_artifact_bucket_arn"></a> [artifact\_bucket\_arn](#output\_artifact\_bucket\_arn) | ARN of the artifact S3 bucket. |
| <a name="output_canary_arns"></a> [canary\_arns](#output\_canary\_arns) | Map of canary key to Synthetics canary ARN. |
| <a name="output_canary_names"></a> [canary\_names](#output\_canary\_names) | Map of canary key to AWS canary name. |
| <a name="output_execution_role_arns"></a> [execution\_role\_arns](#output\_execution\_role\_arns) | Map of canary key to IAM execution role ARN. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
