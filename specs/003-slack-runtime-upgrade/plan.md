# Implementation Plan: Supported Slack reporter runtime

**Branch**: `003-slack-runtime-upgrade` | **Date**: 2026-10-13
**Spec**: [spec.md](spec.md)

## Summary
In `terraform-aws-monitoring/modules/cloudwatch-alarm-actions`, set the existing notify-slack 6.7.0 wrapper runtime explicitly to `python3.12`. Preserve the dependency, inputs, names, IAM, SNS wiring and package code. Validate the pinned handler on Python 3.12 with mocked HTTP and native Terraform mocked-provider plans for primary/secondary regional fixtures. Capture customer-specific read-only inventory and consumer preparation outside the shared repository.

## Technical Context
Terraform >=1.3 consumer floor; existing AWS provider >=4.2,<7.0. Native test runner >=1.7 for mock providers; local Terraform 1.15.7, CI 1.9.8. Handler is upstream notify_slack.py, standard library plus runtime boto3; inspect imports before testing. Tests use Python 3.12. No new variables, dependencies, provider-floor changes or state-address moves.

## Constitution Check
Shared source: DasMeta constitution repository module standards and Speckit module-change gate. Narrow wrapper preserved; no grouped-variable refactor or optional-attribute changes. Existing version layout retained. Generic names only. Modern capabilities rule inactive (improve existing behavior). Tests live in tests, examples are separate. No production apply, invocation or deletion. All gates pass for bounded scope.

## Current State and Gaps
Upstream main selects notify-slack 6.7.0 but inherits Python 3.11 default. Pinning Python 3.12 removes reliance on that AL2 default. Existing non-Slack Python 3.7/3.8/3.9 paths remain outside scope. Repository has docs, tests, pre-commit, CI validation and semantic release; this submodule lacks standalone examples and native test execution, which this change adds narrowly. Speckit tooling is locally bootstrapped from constitution scripts/templates; corresponding spec/plan/tasks are committed in this downstream repository.

## Project Structure
- modules/cloudwatch-alarm-actions/lambda-subsciptions.tf: explicit Slack runtime.
- modules/cloudwatch-alarm-actions/README.md: runtime/support and test commands.
- modules/cloudwatch-alarm-actions/examples/slack/: independent generic consumer configuration.
- modules/cloudwatch-alarm-actions/tests/slack_runtime.tftest.hcl: primary and secondary mock plans.
- modules/cloudwatch-alarm-actions/tests/test_slack_handler.py: actual pinned handler regression tests.
- modules/cloudwatch-alarm-actions/tests/check_slack_runtime_plan.py: inspect verbose Terraform plan JSON for runtime, names, handler and subscriptions.
- .github/workflows/terraform-test.yaml: run scoped tests after existing initialization/validation.
- specs/003-slack-runtime-upgrade/: corresponding design and execution evidence.

## Validation and Rollout
Run init -backend=false, validate, mocked tests, inspect actual planned Lambda attributes, and execute handler tests under Python 3.12. Read current two regional live configurations without reading environment variables or sending notifications. Consumer root uses an older account module that pins an older monitoring release; adoption requires a versioned monitoring release and account dependency change, followed by an actual saved consumer plan. Do not claim mocked plans are production plans. Preserve published versions and existing function identifiers. Review package/OS compatibility before apply. Production deployment approval is the final separate action.

## Risks and Rollback
AL2-to-AL2023 migration changes OS and Python; upstream handler regression tests cover alarm envelopes and error propagation, but cannot prove AWS delivery. Retain code hashes/config and old immutable versions; rollback depends on current AWS deprecated-runtime policy. A full account release upgrade may change unrelated resources; require a bounded consumer plan before adoption.
