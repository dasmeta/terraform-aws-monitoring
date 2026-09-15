# Selective Security Service Alerts Implementation Plan

**Goal:** Add independent finding-notification selectors for Security Hub, GuardDuty, Inspector, and Macie.

**Architecture:** Keep the existing Security Hub EventBridge resource address and control its state for compatibility. Create direct EventBridge rules only for enabled native services, target the existing notification SNS topic, and include their ARNs in its policy.

Reuse the existing GuardDuty-aware `notify-slack` dependency for Slack. Add only the missing Opsgenie updater as an opt-in predefined Lambda subscription inside `cloudwatch-alarm-actions`; it consumes the same SNS event and updates the alert created by the existing Opsgenie HTTPS subscription.

**Tech Stack:** Terraform, AWS EventBridge, SNS, Lambda Python 3.12, native Terraform tests, Python unit tests.

## Current State and Standards

- Scope: `modules/security-hub` for routing and `modules/cloudwatch-alarm-actions` for the missing optional Opsgenie enrichment; both reuse existing grouped inputs and notification submodules.
- Wrapper preservation: one grouped object adds four opinionated booleans; it does not expose arbitrary EventBridge patterns.
- Provider capability: AWS provider `>= 5.0, < 7.0` supports EventBridge rule patterns and targets. Classification: supported.
- Governance source: DasMeta terraform-module-developer standards from the constitution skill.
- Speckit evidence: this package supplies `spec.md`, `plan.md`, and `tasks.md`; no module bootstrap or provider version change is required.
- Breaking/interface widening: additive and backward compatible. Existing Security Hub automatic alerts remain enabled by default.

## Files

- Modify `modules/security-hub/variables.tf`: grouped alert selector.
- Modify `modules/security-hub/local.tf`: native service patterns and selected rules.
- Modify `modules/security-hub/eventbridge.tf`: state control, direct rules, and targets.
- Modify `modules/security-hub/data.tf`: authorize new rules to publish.
- Modify `modules/security-hub/main.tf`: policy dependency.
- Modify `modules/security-hub/README.md`: behavior and GuardDuty-only YAML/HCL example.
- Create `modules/security-hub/selective_alerts.tftest.hcl`: focused plan assertions.
- Modify `modules/cloudwatch-alarm-actions/variables.tf` and `lambda-subsciptions.tf`: opt-in updater configuration and Lambda subscription.
- Modify `modules/cloudwatch-alarm-actions/modules/lambda-subscription/variables.tf` and `main.tf`: allow the updater to use Python 3.12 while preserving current runtimes.
- Create `modules/cloudwatch-alarm-actions/modules/lambda-subscription/src/opsgenie-guardduty/lambda.py`: production-equivalent enrichment handler.
- Create `modules/cloudwatch-alarm-actions/tests/opsgenie-guardduty/test_lambda.py`: focused handler tests.
- Create `modules/cloudwatch-alarm-actions/opsgenie_guardduty.tftest.hcl`: disabled, enabled, and API-key validation plan tests.
- Modify `modules/cloudwatch-alarm-actions/README.md`: explain alert creation, alias matching, and optional enrichment.

## CI Repair

The pull-request workflows currently fail before evaluating this change. The pinned TFLint and Terraform Test wrappers configure an expired repository AWS access key, while the pinned Checkov wrapper uses `actions/setup-python@v1` with an unavailable Python 3.11.11 build. Pull request #93 has the same three failed workflows, and `meta exec buycycle production` confirms that valid managed AWS access plus the changed-module Terraform and TFLint commands succeed.

Keep the existing module matrices and remove the unrelated static AWS credential dependency from validation:

- Modify `.github/workflows/terraform-test.yaml`: use `actions/checkout@v4` and `hashicorp/setup-terraform@v3`, initialize every module with `terraform init -backend=false`, and run `terraform test` with Terraform 1.9.8. The new plan tests mock AWS and pass without credentials.
- Modify `.github/workflows/tflint.yaml`: use `actions/checkout@v4` and the official `terraform-linters/setup-tflint@v6.3.1`, then run `tflint --force` in each matrix directory. `--force` preserves the current advisory policy for lint findings, while setup and execution errors still fail the job; no step-level `continue-on-error` is used.
- Modify `.github/workflows/checkov.yaml`: call the official Checkov v12 action directly by immutable commit, with `soft_fail: true` to preserve the current advisory policy for scan findings. Do not use step-level `continue-on-error`, so action setup and scanner execution errors still fail the job.
- Validate the workflow YAML, rerun the changed-module Terraform and TFLint commands without AWS credentials, push the repair, and use the GitHub Actions results as the integration test.
