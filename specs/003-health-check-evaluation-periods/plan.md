# Implementation Plan: Health Check Alarm Evaluation Periods

## Summary

Expose `evaluation_periods` and `datapoints_to_alarm` for Route53 health-check main and percentage alarms in `modules/alerts`. Preserve the current default evaluation behavior for consumers that omit the new fields, and add fixture coverage for explicit "5 out of 5" health-check alarms.

## Scope

- Add optional `evaluation_periods` and `datapoints_to_alarm` fields to `health_checks[*].main`.
- Add optional `evaluation_periods` and `datapoints_to_alarm` fields to `health_checks[*].percentage`.
- Carry both values through `local.health_check_alerts`.
- Pass both values to `module "external_health_check-alarms"`.
- Update the external-health-check fixture and generated README documentation.

## Design Decisions

- Keep `evaluation_periods` defaulted to `1` for backward compatibility.
- Default `datapoints_to_alarm` to the configured `evaluation_periods` when omitted, so `evaluation_periods = 5` naturally means "5 out of 5" unless the caller overrides it.
- Leave non-health-check alarm types unchanged.

## Technical Context

- Language: Terraform
- Primary files: `modules/alerts/variables.tf`, `modules/alerts/health-checks.tf`, `modules/alerts/main.tf`
- Documentation files: `modules/alerts/README.md`
- Test files: `modules/alerts/tests/external-health-check-alerts/1-example.tf`
- Wrapped dependency: `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` version `5.7.2`

## Risks and Mitigations

- Risk: Changing defaults could alter existing alarm behavior.
  - Mitigation: Preserve default `evaluation_periods = 1`; only explicit caller input changes behavior.
- Risk: `datapoints_to_alarm` drift remains if not exposed.
  - Mitigation: Expose it and default to the evaluation-period count.
- Risk: Documentation drift hides the new inputs.
  - Mitigation: Regenerate README docs through the existing Terraform docs hook.

## Validation Strategy

- Run `terraform fmt -check -recursive`.
- Run `terraform validate` for `modules/alerts`.
- Run `terraform validate` for `modules/alerts/tests/external-health-check-alerts`.
- Run pre-commit hooks before committing.

## Files in Scope

- `modules/alerts/variables.tf`
- `modules/alerts/health-checks.tf`
- `modules/alerts/main.tf`
- `modules/alerts/README.md`
- `modules/alerts/tests/external-health-check-alerts/1-example.tf`
- `modules/alerts/tests/external-health-check-alerts/README.md`
