# Tasks: Alert Description Metadata

## Completed

- [x] Add root-module `client_name` variable in `vaiables.tf`.
- [x] Resolve `alarm_client_name` with fallback behavior in `health-checks-and-alerts.tf`.
- [x] Pass `client_name` into `module "health-check"` in `health-checks-and-alerts.tf`.
- [x] Pass `client_name` into `module "alerts"` in `health-checks-and-alerts.tf`.
- [x] Pass `client_name` into `module "alerts_slo_sli_sla"` in `health-checks-and-alerts.tf`.
- [x] Add alerts-submodule `client_name` variable in `modules/alerts/variables.tf`.
- [x] Generate enriched `alarm_description` values for standard and expression alerts in `modules/alerts/main.tf`.
- [x] Switch standard, anomaly-detection, log-based, external health-check, and expression alarm modules to use generated `alarm_description` values in `modules/alerts/main.tf`.
- [x] Generate enriched health-check alarm descriptions for main and percentage alarms in `modules/alerts/health-checks.tf`.
- [x] Update root module inputs documentation in `README.md`.
- [x] Update alerts submodule inputs documentation in `modules/alerts/README.md`.
- [x] Add a dedicated metadata test scenario under `tests/with-client-name/`.

## Verification

- [ ] Run `terraform validate` for the module or a representative test configuration.
- [ ] Confirm rendered alarm descriptions preserve existing user description text when present.
- [ ] Confirm `client_name` fallback behavior is documented consistently between Terraform variables and README tables.
- [ ] Confirm `tests/with-client-name/1-example.tf` plans successfully and renders expected account/source metadata outputs.
