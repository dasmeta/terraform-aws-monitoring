# AWS Inspector v2 Module

This module sets up AWS Inspector v2, which is **RECOMMENDED** for EC2/EKS vulnerability scanning.

> **Note**: While this module can be used independently, it is **designed and recommended** to be used through the [security-hub](../security-hub) module as a dependency. The security-hub module provides integrated management of Inspector along with other security services (Config, GuardDuty, Macie) and centralized alerting for all findings.

## Why AWS Inspector is Recommended

AWS Inspector v2 scans EC2 instances, container images (ECR), and Lambda functions for vulnerabilities.
- **LAMBDA**: Scans Lambda function configuration (runtime, permissions)
- **LAMBDA_CODE**: Scans Lambda function code (dependencies, vulnerabilities in code)
Both `LAMBDA` and `LAMBDA_CODE` are enabled by default for comprehensive Lambda scanning.

**Important**: When Inspector is enabled, it automatically scans resources across **ALL regions** in the account. There's no need to configure regions separately.

Findings are automatically sent to Security Hub, providing comprehensive security coverage for your compute resources.

## 🌍 Multi-Region Support

**AWS Inspector v2 automatically scans resources across all regions** when enabled. Unlike Config, GuardDuty, and Macie, Inspector does not require per-region deployment. A single deployment enables scanning across your entire AWS account.

- **Automatic multi-region**: Inspector v2 scans EC2, ECR, and Lambda resources in all regions automatically
- **Findings aggregation**: Findings from all regions are automatically sent to Security Hub and aggregated via Security Hub's finding aggregator
- **No per-region setup required**: Deploy this module once per account, and it handles all regions

## Usage

### Basic Usage

```hcl
module "inspector" {
  source  = "dasmeta/monitoring/aws//modules/inspector"
  # version = "x.y.z"  # It's important to check and set the module version exact when using in real setups to not get accidental auto upgrades

  # Enable for EC2, ECR, LAMBDA, and LAMBDA_CODE (default)
  # LAMBDA scans Lambda function configuration (runtime, permissions)
  # LAMBDA_CODE scans Lambda function code (dependencies, vulnerabilities)
  # Inspector automatically scans all regions in the account
  resource_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}
```

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.0  |
| aws       | >= 4.0  |

## Inputs

| Name           | Description                                                                                          | Type           | Default                                   | Required |
| -------------- | ---------------------------------------------------------------------------------------------------- | -------------- | ----------------------------------------- | :------: |
| enable         | Enable AWS Inspector v2. Scans resources across all regions in the account.                          | `bool`         | `true`                                    |    no    |
| resource_types | Resource types to enable Inspector for. Valid values: EC2, ECR, LAMBDA, LAMBDA_CODE, CODE_REPOSITORY | `list(string)` | `["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]` |    no    |

## Outputs

| Name           | Description                          |
| -------------- | ------------------------------------ |
| enabled        | Whether AWS Inspector v2 is enabled  |
| resource_types | Resource types enabled for Inspector |
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_inspector2_enabler.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_enabler) | resource |
| [aws_inspector2_filter.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_filter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_filters"></a> [filters](#input\_filters) | Map of findings filters to create. Key is the filter name. If empty, no filters will be created. | <pre>map(object({<br/>    description   = optional(string)<br/>    filter_action = string # Valid values: ARCHIVE, NOOP<br/>    filter_criteria = optional(object({<br/>      aws_account_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      component_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      component_type = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      ec2_instance_image_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      ec2_instance_subnet_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      ec2_instance_vpc_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      ecr_image_pushed_at = optional(object({<br/>        end_inclusive   = optional(string)<br/>        start_inclusive = optional(string)<br/>      }))<br/>      ecr_image_tags = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      ecr_image_hash = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      finding_arn = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      finding_status = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      finding_type = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      first_observed_at = optional(object({<br/>        end_inclusive   = optional(string)<br/>        start_inclusive = optional(string)<br/>      }))<br/>      inspector_score = optional(object({<br/>        lower_inclusive = optional(number)<br/>        upper_inclusive = optional(number)<br/>      }))<br/>      last_observed_at = optional(object({<br/>        end_inclusive   = optional(string)<br/>        start_inclusive = optional(string)<br/>      }))<br/>      network_protocol = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      port_range = optional(object({<br/>        begin_inclusive = optional(number)<br/>        end_inclusive   = optional(number)<br/>      }))<br/>      related_vulnerabilities = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      resource_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      resource_tags = optional(object({<br/>        comparison = string<br/>        key        = string<br/>        value      = optional(string)<br/>      }))<br/>      resource_type = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      severity = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      title = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      updated_at = optional(object({<br/>        end_inclusive   = optional(string)<br/>        start_inclusive = optional(string)<br/>      }))<br/>      vendor_severity = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      vulnerability_id = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>      vulnerability_source = optional(object({<br/>        comparison = string<br/>        value      = string<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_types"></a> [resource\_types](#input\_resource\_types) | Resource types to enable Inspector for. Valid values: EC2, ECR, LAMBDA, LAMBDA\_CODE, CODE\_REPOSITORY. LAMBDA scans Lambda function configuration (runtime, permissions). LAMBDA\_CODE scans Lambda function code (dependencies, vulnerabilities). Both LAMBDA and LAMBDA\_CODE are recommended for comprehensive Lambda scanning. | `list(string)` | <pre>[<br/>  "EC2",<br/>  "ECR",<br/>  "LAMBDA",<br/>  "LAMBDA_CODE"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_filters"></a> [filters](#output\_filters) | Map of Inspector filter resources (key is filter name) |
| <a name="output_resource_types"></a> [resource\_types](#output\_resource\_types) | Resource types enabled for Inspector |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
