# Validation evidence

Date: 2026-10-13. Base: upstream main 42df3c3.

- Terraform 1.15.7, AWS provider 5.100.0: module initialization and validation passed. An existing verified local provider binary was reused after a disk-space failure downloading a fresh provider; no provider constraint was changed.
- Terraform AWS provider 6.56.0: validation and both native tests also passed; existing aws_region.name deprecation warnings remain outside this runtime change.
- Native credential-free Terraform tests: two regional runs passed. The planned-resource checker failed against the original Python 3.11 default and passed after explicitly selecting Python 3.12.
- Planned-resource checks: each regional run contains one Python 3.12 reporter with unchanged function naming and notify_slack.lambda_handler; Exact regional SNS source ARN and invocation permission function/principal/action remain intact; Lambda and unrelated HTTPS subscription types remain present. The subscription endpoint is computed during plan, so exact deployed endpoint preservation still requires the real consumer plan.
- Actual pinned upstream notify-slack 6.7.0 handler on Python 3.12: four tests passed, including six state/region cases, Unicode alarm text, HTTP error status, transport failure propagation and malformed-alarm handling. AWS clients and HTTP transport were mocked.
- Private consumer-derived dual-region configuration: one native mocked plan passed; both expected names, Python 3.12, handler, 128 MiB memory and 30-second timeout verified. Customer identifiers and account evidence are held outside this repository.
- Read-only deployed configuration confirmed both in-scope reporters still use Python 3.8 with version 1 retained, no aliases and unqualified SNS Lambda endpoints. No deployment or notification was performed.

- Scoped pre-commit checks passed, including formatting, generated documentation, YAML and secret scanning.

## Remaining deployment boundary

This verifies module configuration and handler compatibility on local Python 3.12; it does not prove live AL2023 delivery. CI reruns the credential-free tests. Adoption requires a monitoring release containing this change, an account dependency update, then a saved real consumer Terraform plan reviewed for unrelated changes and separately approved deployment. Existing immutable versions require separate caller/retention decisions.

## Independent review

Review found no critical or important issues. Reviewer checked the runtime diff, generic naming, test behavior and Terraform 1.9.8 JSON output compatibility against its source. Minor contract/checker gaps were corrected: fixture field descriptions and exact SNS source/permission checks.
