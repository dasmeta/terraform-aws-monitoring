# Quickstart and verification

Run `terraform fmt -check -recursive`, `terraform init -backend=false`, `terraform validate`, and `terraform test -filter=tests/cspm_alerting.tftest.hcl` from `modules/security-hub/` with Terraform >= 1.6. Review an enabled plan for one SQS queue, two SNS targets with retry/DLQ settings, and a rule-scoped queue policy. After a separately approved non-production apply, trace one finding to destination receipt and one controlled failure to the queue. Keep the live evidence outside this repository.

Validation on 2026-10-27: module `terraform validate` passed with existing deprecation warnings; focused native tests passed 2/2; repository `terraform fmt -check -recursive` and `git diff --check` passed. The repository-wide `terraform_docs` pre-commit hook rewrote thousands of unrelated existing Markdown lines due local formatter drift, so the generated table was updated only for `modules/security-hub/README.md` and that hook was skipped for this commit. All other commit hooks passed.

GitHub Checkov initially failed before scanning because the reusable action requested Python 3.14.3 on Ubuntu 26.04, for which no build exists. Its existing job is pinned to Ubuntu 24.04, which has a published Python 3.14.3 x64 build; check the new PR run before release.
