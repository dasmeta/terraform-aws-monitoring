# Amazon Macie v2 Basic Example

This example demonstrates the basic usage of the Amazon Macie v2 module.

## What This Example Does

- Enables Amazon Macie v2 for the account
- Automatically discovers and protects sensitive data in S3 buckets
- Scans S3 buckets across all regions

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Cleanup

```bash
terraform destroy
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_macie"></a> [macie](#module\_macie) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
