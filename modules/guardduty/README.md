# AWS GuardDuty Module

This module sets up AWS GuardDuty, which provides intelligent threat detection for your AWS infrastructure.

> **Note**: While this module can be used independently, it is **designed and recommended** to be used through the [security-hub](../security-hub) module as a dependency. The security-hub module provides integrated management of GuardDuty along with other security services (Config, Inspector, Macie) and centralized alerting for all findings.

## Why AWS GuardDuty

AWS GuardDuty is a threat detection service that continuously monitors for malicious activity and unauthorized behavior to protect your AWS accounts, workloads, and data stored in Amazon S3. Findings are automatically sent to Security Hub.

## ⚠️ Region-Specific Service

**AWS GuardDuty is a region-specific service.** This module creates a GuardDuty detector in the AWS provider's current region only.

- **To enable GuardDuty in multiple regions**: Deploy this module separately in each region (using provider aliases or separate Terraform workspaces)
- **Findings aggregation**: When used through the Security Hub module, findings from all regions are automatically aggregated via Security Hub's finding aggregator (`link_mode = "ALL_REGIONS"` or `link_mode = "SPECIFIED_REGIONS"`)
- **Current region**: The module will handle data only in the AWS provider's configured region

## Usage

### Basic Usage

```hcl
module "guardduty" {
  source  = "dasmeta/monitoring/aws//modules/guardduty"
  # version = "x.y.z"  # It's important to check and set the module version exact when using in real setups to not get accidental auto upgrades

  enable = true
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.3  |
| aws       | ~> 5.0  |

## Inputs

| Name                         | Description                                 | Type     | Default             | Required |
| ---------------------------- | ------------------------------------------- | -------- | ------------------- | :------: |
| enable                       | Enable AWS GuardDuty                        | `bool`   | `false`             |    no    |
| finding_publishing_frequency | Frequency of notifications for findings     | `string` | `"FIFTEEN_MINUTES"` |    no    |
| enable_s3_protection         | Enable S3 protection in GuardDuty           | `bool`   | `true`              |    no    |
| enable_kubernetes_protection | Enable Kubernetes audit log protection      | `bool`   | `true`              |    no    |
| enable_malware_protection    | Enable malware protection for EC2 instances | `bool`   | `true`              |    no    |

## Outputs

| Name        | Description                      |
| ----------- | -------------------------------- |
| detector_id | The ID of the GuardDuty detector |
| enabled     | Whether AWS GuardDuty is enabled |
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
| [aws_guardduty_detector.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_filter) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_kubernetes_protection"></a> [enable\_kubernetes\_protection](#input\_enable\_kubernetes\_protection) | Enable Kubernetes audit log protection in GuardDuty | `bool` | `true` | no |
| <a name="input_enable_malware_protection"></a> [enable\_malware\_protection](#input\_enable\_malware\_protection) | Enable malware protection for EC2 instances in GuardDuty | `bool` | `true` | no |
| <a name="input_enable_s3_protection"></a> [enable\_s3\_protection](#input\_enable\_s3\_protection) | Enable S3 protection in GuardDuty | `bool` | `true` | no |
| <a name="input_filters"></a> [filters](#input\_filters) | Map of findings filters to create. Key is the filter name. If empty, no filters will be created. | <pre>map(object({<br/>    description = optional(string)<br/>    action      = string # Valid values: ARCHIVE, NOOP<br/>    rank        = optional(number)<br/>    finding_criteria = optional(object({<br/>      criterion = optional(map(object({<br/>        equals                = optional(list(string))<br/>        not_equals            = optional(list(string))<br/>        greater_than          = optional(number)<br/>        greater_than_or_equal = optional(number)<br/>        less_than             = optional(number)<br/>        less_than_or_equal    = optional(number)<br/>      })))<br/>    }))<br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_finding_publishing_frequency"></a> [finding\_publishing\_frequency](#input\_finding\_publishing\_frequency) | Specifies the frequency of notifications sent for finding occurrences. Valid values: FIFTEEN\_MINUTES, ONE\_HOUR, SIX\_HOURS | `string` | `"FIFTEEN_MINUTES"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_detector_id"></a> [detector\_id](#output\_detector\_id) | The ID of the GuardDuty detector |
| <a name="output_filters"></a> [filters](#output\_filters) | Map of GuardDuty filter resources (key is filter name) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
