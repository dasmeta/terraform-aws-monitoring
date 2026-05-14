# Implementation Plan: Alert Description Metadata

## Summary

Document the completed monitoring-module changes that add client-aware CloudWatch alarm descriptions and align module documentation with the new input.

## Scope

- Add a root-module `client_name` input without inferring it from the dashboard name.
- Propagate the resolved client value into all alert-producing submodule calls.
- Generate enriched alarm descriptions for standard, expression, and health-check alarm variants.
- Update README documentation for root and alerts submodule inputs.
- Add a dedicated test scenario for metadata-related alarm paths without changing the base test.

## Design Decisions

- Resolve `client_name` once in the root module and reuse it across submodules only when it is explicitly provided.
- Use newline-separated description metadata for readability in CloudWatch.
- Preserve existing per-alert description text before appended metadata.
- Build CloudWatch console source links from current region and alarm name, URL-encoding alarm identifiers.
- Use `"unknown"` only inside the alerts submodule as a defensive fallback if it is invoked without a resolved client value.

## Technical Context

- Language: Terraform
- Primary files: `vaiables.tf`, `health-checks-and-alerts.tf`, `modules/alerts/main.tf`, `modules/alerts/health-checks.tf`
- Documentation files: `README.md`, `modules/alerts/README.md`
- Test files: `tests/with-client-name/*`
- External dependency: `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` version `4.3.0`

## Risks and Mitigations

- Risk: Alarm source URLs could break for names containing spaces or special characters.
  - Mitigation: URL-encode alarm names before concatenating console links.
- Risk: Blank `client_name` values could create misleading metadata if inferred from unrelated fields.
  - Mitigation: Trim input and leave it unset when not explicitly provided.
- Risk: Documentation drift could hide the new input from consumers.
  - Mitigation: Update both README input tables alongside Terraform variable declarations.

## Validation Strategy

- Confirm `client_name` is declared in root and alerts-module variable definitions.
- Confirm the resolved client value is passed to `health-check`, `alerts`, and `alerts_slo_sli_sla` module calls.
- Confirm all alarm modules now consume generated `alarm_description` fields.
- Confirm README inputs tables include `client_name` with the intended descriptions.
- Confirm `tests/with-client-name/1-example.tf` exercises `client_name` and expected account/source metadata without changing `tests/base`.

## Files in Scope

- `README.md`
- `health-checks-and-alerts.tf`
- `modules/alerts/README.md`
- `modules/alerts/health-checks.tf`
- `modules/alerts/main.tf`
- `modules/alerts/variables.tf`
- `tests/with-client-name/0-setup.tf`
- `tests/with-client-name/1-example.tf`
- `tests/with-client-name/README.md`
- `vaiables.tf`
