# Tasks: Health Check Alarm Evaluation Periods

## Implementation

- [x] Add `evaluation_periods` and `datapoints_to_alarm` fields to health-check main alarm input schema.
- [x] Add `evaluation_periods` and `datapoints_to_alarm` fields to health-check percentage alarm input schema.
- [x] Carry the configured values into `local.health_check_alerts`.
- [x] Pass the configured values to `module "external_health_check-alarms"`.
- [x] Update external-health-check fixture coverage.
- [x] Regenerate module README documentation.

## Verification

- [x] Run `terraform fmt -check -recursive`.
- [x] Run `terraform validate` in `modules/alerts`.
- [x] Run `terraform validate` in `modules/alerts/tests/external-health-check-alerts`.
- [x] Run pre-commit hooks.
