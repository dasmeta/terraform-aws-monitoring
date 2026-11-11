# Implementation Plan: CloudWatch Metric Query Account ID Stability

## Summary

Fix the alerts submodule so standard same-account CloudWatch metric alarms do not place a computed AWS caller identity account ID inside `metric_query`. The provider bug is triggered when that nested set element changes from unknown during planning to known during apply.

## Required Plan Sections

### Current Repository Module State

- Repository: `terraform-aws-monitoring`
- Target module: `modules/alerts`
- Current branch baseline: `main`, fast-forwarded from `origin/main` on 2026-08-28.
- The alerts submodule wraps `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` version `5.7.2`.
- Standard metric alarms, anomaly-detection alarms, log-based alarms, health-check alarms, and expression alarms are all represented in `modules/alerts/main.tf` and `modules/alerts/health-checks.tf`.

### Gaps Versus Internal Standards

- The target module already follows the repository's established wrapper pattern.
- This change does not introduce broad new inputs or resource ownership boundaries.
- Existing naming contains hyphenated module labels; this change preserves them to avoid unrelated state churn.

### Wrapper-Preservation Assessment

- Public input shape remains unchanged.
- Existing `alerts[*].account_id` remains the explicit cross-account escape hatch.
- Same-account behavior uses CloudWatch's default account handling instead of deriving the same account ID through Terraform data.

### Provider Collection Checked

- Not applicable. This is an existing module bugfix, not new-module creation.

### Candidate Upstream Modules Considered

- Not applicable. The existing upstream wrapper remains `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm`.

### Chosen Wrapper Baseline

- Preserve the current DasMeta wrapper and upstream metric-alarm module.
- Adjust only the optional `account_id` value passed into metric query objects.

### Constitution Source Used

- `/Users/Adeline/.agents/skills/constitution/terraform-module-developer/references/internal-module-standards.md`
- `/Users/Adeline/.agents/skills/constitution/terraform-module-developer/references/planning-checklist.md`
- `/Users/Adeline/.agents/skills/constitution/terraform-module-developer/references/speckit-module-workflow.md`

### Speckit Evidence

- Feature directory: `specs/002-cloudwatch-metric-query-account-id/`
- Required files: `spec.md`, `plan.md`, `tasks.md`
- The repository has a `specs/` directory but no `.specify/` command scaffold, so the evidence is created manually in the existing local format.

### Module-Change Gate Compatibility

- Expected to pass once `spec.md`, `plan.md`, and `tasks.md` are committed with the module changes.

### Fallback Rationale

- No direct-resource fallback is needed inside the module. The existing wrapper can represent the desired alarm behavior.

### Upstream Scratch Template Gaps

- Not applicable. This is not new-module scaffolding.

### Proposed File Changes

- Add mocked Terraform regression test coverage under `modules/alerts/tests/`.
- Update `modules/alerts/main.tf` so optional metric query `account_id` is `null` unless explicitly provided.
- Update README only if the rendered consumer-facing behavior changes enough to require documentation.

### Potential Breaking Changes

- None expected. Public variables and outputs remain unchanged.

### Potential Interface-Widening Changes

- None. No new input is required for this fix.

### Conflicts Requiring Approval

- None identified.

## Validation Strategy

- Run the new Terraform test and confirm it fails before implementation.
- Apply the module fix.
- Re-run the Terraform test and confirm it passes.
- Run `terraform fmt -check`.
- Run `terraform validate` for `modules/alerts`.
