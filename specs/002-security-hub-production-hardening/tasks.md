# Tasks

- [x] Verify PR head, current behavior, and official Inspector/DynamoDB constraints.
- [x] Add regression tests for equal-time policy changes, stale/out-of-order events, exact digest acknowledgement, and accepted-ledger routing.
- [x] Integrate bounded positive ECR use evidence with unknown fallback; test missing and failed lookups.
- [x] Implement incident-to-remediation closure and P2/P1 transition tests.
- [x] Test GuardDuty probes, duplicate delivery, urgent findings, alias lifecycle, and migration.
- [x] Benchmark the ledger's capacity bound, record live read/timeout behavior, and identify the unresolved scale blocker.
- [x] Update Terraform input, IAM, documentation, and validate compatibility.
- [x] Finish final Python, Terraform, and static checks; review the staged diff and provide rollout verdict.

The production-volume worker redesign, live legacy migration canary, and Opsgenie team-routing verification remain release blockers outside this bounded patch.
