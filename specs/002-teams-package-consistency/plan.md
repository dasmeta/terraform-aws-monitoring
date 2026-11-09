# Implementation Plan: Consistent notification package creation

**Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)

## Summary

In dasmeta/terraform-aws-monitoring, gate the existing local package filename on the archive provider's computed output_size before passing it to the Lambda 6.8 wrapper. Keep Teams enabled and all resource identities stable.

## Technical context and current state

Terraform 1.13+ checks filesystem-function result consistency. The subscription wrapper passes a known filename into Lambda 6.8 before archive_file creates it. Parent SNS dependencies defer the archive until apply. A scratch reproduction on Terraform 1.14.5 fails with the existing expression; referencing output_path alone also fails; gating on computed output_size passes.

Affected implementation: modules/cloudwatch-alarm-actions/modules/lambda-subscription/main.tf. Existing AWS mock tests live under modules/cloudwatch-alarm-actions/tests. AWS provider 5.x compatibility must be retained. An upstream Lambda 8.x upgrade would require a provider migration and is outside scope.

## Constitution and standards check

Use the local terraform-module-developer skill and its bundled internal standards, sourced from the Infra Governance repository. This is improve mode with no net-new ability: the modern-capabilities rule is not active. Preserve the existing opinionated wrapper, grouped caller inputs, optionality, version files, and public interface. No direct-resource fallback, interface widening, breaking change, or standards conflict is proposed.

Speckit was initialized locally; specify, plan, tasks, implement are used in this downstream repository. The package contains spec.md, plan.md, and tasks.md before module edits. Local tool scaffolding is excluded from delivery; corresponding feature evidence is committed. No module-change gate currently exists in this repository.

## Files and design

- main.tf in the subscription wrapper: wait for computed archive size before exposing its path.
- modules/cloudwatch-alarm-actions/tests/teams_package_consistency.tftest.hcl: compatibility apply of two real Teams subscriptions with mocked AWS.
- modules/cloudwatch-alarm-actions/tests/test_package_consistency.py: run the production package argument through real Terraform filesystem evaluation and real deferred ZIP creation; mocked AWS alone does not exercise this check.
- .github/workflows/notification-package-test.yaml: run the regression on Terraform 1.14.5, where filesystem consistency is enforced.
- modules/cloudwatch-alarm-actions/README.md: document clean-run packaging behavior and regression command.
- This feature package: requirements, decisions, tasks, and validation evidence.

No variables, outputs, provider constraints, runtimes, naming, or existing subscription addresses change. Empty ZIPs are not expected; a generated ZIP always has a positive size. Keep the dependency expression inside the producer wrapper, not the downloaded upstream cache.

## Validation and release

Run the real filesystem-evaluation regression against unmodified code from an empty temporary directory and capture its expected failure. The native mocked-AWS test alone passes old code because mocks do not consume the package; retain it as compatibility coverage. Apply the fix, remove only those scratch build artifacts, rerun the same regression, then rerun it with existing archives. Run existing Teams sensitivity and Slack uniqueness tests, scoped Terraform validation, formatting, and diff checks. Test infrastructure is fully mocked; no AWS or HCP apply is permitted.

Commit with a conventional fix title, open a reviewed PR, and use semantic-release after merge to main. Do not reserve 3.2.1 because other pending fixes may publish first. Observe the actual release before changing the consumer YAML pin.

## Risks

The module still shares archive paths between equivalent subscription instances; that pre-existing independent concern is not broadened into this ordering fix. Confirm the real regression with two instances. A clean HCP runner differs from a warm local runner, so clean-directory coverage is required. The production apply may be partial and must be replanned after rollout.

## Validation evidence

- Original argument: filesystem regression failed with fileexists changing from false to true during apply.
- Fixed argument: filesystem regression passed both clean and existing-package applies on Terraform 1.14.5 / Archive 2.8.1.
- Native apply/plan coverage: sensitive Teams (2), Slack package uniqueness (1), and Teams package compatibility (2), all five passing with AWS mocked.
- Scoped terraform validate, terraform fmt -check, and git diff --check passed.
- Independent code review is required before merge; HCP production rollout remains separate.
