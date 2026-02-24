# AWS GuardDuty Basic Example

This example demonstrates the basic usage of the AWS GuardDuty module with default settings.

## What This Example Does

- Enables AWS GuardDuty with default settings
- Enables S3, Kubernetes, and malware protection
- Sets finding publishing frequency to 15 minutes

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
| <a name="module_guardduty"></a> [guardduty](#module\_guardduty) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
