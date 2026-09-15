# terraform-aws-monitoring Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-09-15

## Active Technologies

- Terraform `~> 1.3`; consumer-owned Python compatible with `syn-python-selenium-11.1` + `hashicorp/aws >= 5.0, < 7.0`
- `hashicorp/archive ~> 2.7` is allowed only to package consumer-owned source files in `modules/cloudwatch-synthetics`. The `archive_file` **resource** is required so Terraform Cloud apply workers build the ZIP in the apply graph; the data source is not used because it builds during plan.

## Project Structure

```text
modules/cloudwatch-synthetics/  # Published Terraform submodule
docs/superpowers/               # Design and implementation notes for this change
```

## Commands

terraform fmt -check -recursive modules/cloudwatch-synthetics
terraform -chdir=modules/cloudwatch-synthetics init -backend=false
terraform -chdir=modules/cloudwatch-synthetics validate
bash modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh

## Code Style

- Keep public Terraform generic: no vendor/client endpoints, protocol templates, or secrets.
- Consumer-owned canary behavior belongs in private source files. The archive provider may record those file contents in Terraform plan/state data, so consumers must restrict state access to people allowed to read that code.
- Source symlinks are unsupported. Keep module inputs, README, and public tests aligned.

## Recent Changes

- Package canaries from Terraform-root-relative source files; look up secrets and SNS topics by name
- Added generic CloudWatch Synthetics submodule
- Add client, account, and source metadata to alarm descriptions

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
