# Amazon Macie v2 Module

This module sets up Amazon Macie v2, which provides data security and data privacy services.

> **Note**: While this module can be used independently, it is **designed and recommended** to be used through the [security-hub](../security-hub) module as a dependency. The security-hub module provides integrated management of Macie along with other security services (Config, Inspector, GuardDuty) and centralized alerting for all findings.

## Why Amazon Macie

Amazon Macie is a fully managed data security and data privacy service that uses machine learning and pattern matching to discover and protect your sensitive data in AWS. Macie automatically discovers, classifies, and protects sensitive data stored in Amazon S3. Findings are automatically sent to Security Hub.

## ⚠️ Region-Specific Service

**Amazon Macie is a region-specific service.** This module enables Macie in the AWS provider's current region only.

- **To enable Macie in multiple regions**: Deploy this module separately in each region (using provider aliases or separate Terraform workspaces)
- **Findings aggregation**: When used through the Security Hub module, findings from all regions are automatically aggregated via Security Hub's finding aggregator (`link_mode = "ALL_REGIONS"` or `link_mode = "SPECIFIED_REGIONS"`)
- **Current region**: The module will handle data only in the AWS provider's configured region
- **Note**: While Macie can discover S3 buckets across regions, the Macie service itself must be enabled in each region where you want active monitoring

## Usage

### Basic Usage

```hcl
module "macie" {
  source  = "dasmeta/monitoring/aws//modules/macie"
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

| Name   | Description                                                                                      | Type   | Default | Required |
| ------ | ------------------------------------------------------------------------------------------------ | ------ | ------- | :------: |
| enable | Enable Amazon Macie v2. When enabled, Macie discovers and protects sensitive data in S3 buckets. | `bool` | `false` |    no    |

## Outputs

| Name    | Description                        |
| ------- | ---------------------------------- |
| enabled | Whether Amazon Macie v2 is enabled |
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
| [aws_macie2_account.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_account) | resource |
| [aws_macie2_findings_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_findings_filter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_finding_publishing_frequency"></a> [finding\_publishing\_frequency](#input\_finding\_publishing\_frequency) | Specifies how often to publish updates to policy findings for the account. Valid values: FIFTEEN\_MINUTES, ONE\_HOUR, SIX\_HOURS | `string` | `"FIFTEEN_MINUTES"` | no |
| <a name="input_findings_filters"></a> [findings\_filters](#input\_findings\_filters) | Map of findings filters to create. Key is the filter name (which becomes the field name in criterion). The nested map key in criterion is the field name. If empty, no filters will be created. | <pre>map(object({<br/>    description = optional(string)<br/>    action      = string # Valid values: ARCHIVE, NOOP<br/>    position    = optional(number)<br/>    finding_criteria = optional(object({<br/>      criterion = optional(map(object({<br/>        eq  = optional(list(string))<br/>        gt  = optional(number)<br/>        gte = optional(number)<br/>        lt  = optional(number)<br/>        lte = optional(number)<br/>        neq = optional(list(string))<br/>      })))<br/>    }))<br/>    tags = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_status"></a> [status](#input\_status) | Specifies the status for the account. Valid values: ENABLED, PAUSED | `string` | `"ENABLED"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_created_at"></a> [account\_created\_at](#output\_account\_created\_at) | The date and time, in UTC and extended RFC 3339 format, when the Amazon Macie account was created |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | The ID of the Macie account |
| <a name="output_account_service_role"></a> [account\_service\_role](#output\_account\_service\_role) | The Amazon Resource Name (ARN) of the service-linked role that allows Macie to monitor and analyze data in AWS resources for the account |
| <a name="output_filters"></a> [filters](#output\_filters) | Map of Macie findings filter resources (key is filter name) |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
