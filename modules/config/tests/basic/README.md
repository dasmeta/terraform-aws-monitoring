# AWS Config Basic Example

This example demonstrates the basic usage of the AWS Config module with default settings.

## What This Example Does

- Enables AWS Config with default settings
- Records all supported resource types
- Includes global resources (IAM, etc.)
- Automatically creates an S3 bucket for Config delivery
- Sets delivery frequency to 24 hours

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
| <a name="module_config"></a> [config](#module\_config) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
