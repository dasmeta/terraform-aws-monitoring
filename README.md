# Why
Somehow AWS does not have same tooling out of the box compared to GCP.
Automate creation of Terraform README documentation and format modules before commit to github repo.

## How
Modules to quickly spin up fully functional of monitoring.
Using terraform-docs and terraform fmt and pre-commit hooks

## Requirements for pre-commit hooks
for Run our pre-commit hooks you need to install
	- terraform
	- terraform-docs

## Config for GitHooks

```bash
git config core.hooksPath githooks
```

## What
- terraform-aws-opsgenie
- terraform-docs
- terraform fmt
- pre-commit hooks

