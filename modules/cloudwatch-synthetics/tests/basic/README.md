# Basic test: generic source-file canaries

The fixture creates two isolated module instances, three generic canaries, one
default-key test secret, and one customer-key test secret. It exists only to
validate public Terraform infrastructure. Run lifecycle tests only in a
dedicated non-production account; a customer-managed KMS key enters its
seven-day deletion window during destroy.

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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

| Name | Source | Version |
|------|--------|---------|
| <a name="module_primary"></a> [primary](#module\_primary) | ../../ | n/a |
| <a name="module_secondary"></a> [secondary](#module\_secondary) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_key.customer_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.customer_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.customer_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sns_topic.alerts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
