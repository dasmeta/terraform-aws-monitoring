# Tasks

- [x] Add regression tests for grouped and per-finding EventBridge patterns.
- [x] Filter grouped immediate routing to active HIGH/CRITICAL findings.
- [x] Add regression tests for routine-group skip and open/urgent group processing.
- [x] Reuse the ledger scan to identify group markers and skip inactive groups.
- [x] Add regression tests for urgent-only closure, stable quiet period, and repeat runs.
- [x] Implement group quiet-period state and idempotent closure.
- [x] Add a digest-duration early-warning alarm and test its grouped-only presence.
- [x] Validate focused Python tests and Terraform configuration; inspect the consumer plan after pinning the candidate.
- [ ] Review the diff, update PR 108, and test the pinned candidate in the existing consumer workspace.
