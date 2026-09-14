# Quickstart: Source-File Canaries

1. Store private Python files in the consumer configuration repository, not this public module repository. Use real files, not symlinks; Terraform cannot safely verify a symlink target remains in the workspace.
2. Create an AWS Secrets Manager secret outside this module; export only its name from its managing workspace.
3. Ensure the SNS topic already exists.
4. Pass source-file mappings, secret name, and non-secret `config` as shown in [the public contract](./contracts/module-input.md).
5. Run `terraform plan`; Terraform builds the ZIP automatically, so no manual ZIP command is required.
6. Restrict Terraform state access because package source content can appear in plan/state data.
7. At runtime, `python/canary.py` loads root `config.json`, calls Secrets Manager using its `secret_name`, and performs private consumer-owned behavior.

Packages need canonical `python/...` entries and `python/canary.py` defining `handler(event, context)`. The module fixes runtime to `syn-python-selenium-11.1` and handler to `canary.handler`.
