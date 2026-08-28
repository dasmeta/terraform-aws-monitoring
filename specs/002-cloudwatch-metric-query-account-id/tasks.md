# Tasks: CloudWatch Metric Query Account ID Stability

## Implementation

- [x] Add a mocked Terraform test that exercises a standard metric alert without an explicit `account_id`.
- [x] Verify the test fails against the current `main` implementation.
- [x] Update `modules/alerts/main.tf` so same-account metric queries omit `account_id` instead of using `data.aws_caller_identity`.
- [x] Preserve literal alert-level `account_id` for cross-account metric query use.
- [x] Re-run the regression test and confirm it passes.

## Verification

- [x] Run `terraform fmt -check` for changed Terraform files.
- [x] Run `terraform validate` for `modules/alerts`.
- [x] Review the final diff for accidental interface or documentation drift.

## Notes

- Full `terraform fmt -check` for `modules/alerts` still reports pre-existing formatting drift in `health-checks.tf`, which is outside this change.
