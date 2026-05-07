# Implementation Plan: Alert Description Metadata

## Summary

Document the completed monitoring-module changes that add client-aware CloudWatch alarm descriptions and align module documentation with the new input.

## Scope

- Add a root-module `client_name` input with fallback behavior.
- Propagate the resolved client value into all alert-producing submodule calls.
- Generate enriched alarm descriptions for standard, expression, and health-check alarm variants.
- Update README documentation for root and alerts submodule inputs.
- Add representative base-test configuration for metadata-related alarm paths.

## Design Decisions

- Resolve `client_name` once in the root module and reuse that value across submodules.
- Use newline-separated description metadata for readability in CloudWatch.
- Preserve existing per-alert description text before appended metadata.
- Build CloudWatch console source links from current region and alarm name, URL-encoding alarm identifiers.
- Use `"unknown"` only inside the alerts submodule as a defensive fallback if it is invoked without a resolved client value.

## Technical Context

- Language: Terraform
- Primary files: `vaiables.tf`, `health-checks-and-alerts.tf`, `modules/alerts/main.tf`, `modules/alerts/health-checks.tf`
- Documentation files: `README.md`, `modules/alerts/README.md`
- Test file: `tests/base/1-example.tf`
- External dependency: `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` version `4.3.0`

## Risks and Mitigations

- Risk: Alarm source URLs could break for names containing spaces or special characters.
  - Mitigation: URL-encode alarm names before concatenating console links.
- Risk: Blank `client_name` values could create empty metadata lines.
  - Mitigation: Trim input and fall back to `name` in the root module.
- Risk: Documentation drift could hide the new input from consumers.
  - Mitigation: Update both README input tables alongside Terraform variable declarations.

## Validation Strategy

- Confirm `client_name` is declared in root and alerts-module variable definitions.
- Confirm the resolved client value is passed to `health-check`, `alerts`, and `alerts_slo_sli_sla` module calls.
- Confirm all alarm modules now consume generated `alarm_description` fields.
- Confirm README inputs tables include `client_name` with the intended descriptions.
- Confirm `tests/base/1-example.tf` exercises `client_name`, preserved description text, and expression-alert configuration.

## Files in Scope

- `README.md`
- `health-checks-and-alerts.tf`
- `modules/alerts/README.md`
- `modules/alerts/health-checks.tf`
- `modules/alerts/main.tf`
- `modules/alerts/variables.tf`
- `tests/base/1-example.tf`
- `vaiables.tf`
