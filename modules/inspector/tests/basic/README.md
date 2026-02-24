# AWS Inspector v2 Basic Example

This example demonstrates the basic usage of the AWS Inspector v2 module with default settings.

## What This Example Does

- Enables AWS Inspector v2 with default settings
- Scans EC2 instances, ECR container images, and Lambda functions

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
| <a name="module_inspector"></a> [inspector](#module\_inspector) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
