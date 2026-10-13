# Tasks: Supported Slack reporter runtime

## Phase 1: Setup
- [x] T001 Create isolated upstream-based branch and bootstrap local Speckit support in .specify/.
- [x] T002 Complete corresponding spec, research, plan and contracts in specs/003-slack-runtime-upgrade/.

## Phase 2: Foundations
- [x] T003 Initialize modules/cloudwatch-alarm-actions/ and inspect the installed notify-slack handler and dependencies.

## Phase 3: User Story 1 — supported alarm delivery
- [x] T004 [US1] Add representative mocked SNS/Slack handler regressions in modules/cloudwatch-alarm-actions/tests/test_slack_handler.py.
- [x] T005 [US1] Add native mocked-provider plans and planned-resource assertions in modules/cloudwatch-alarm-actions/tests/slack_runtime.tftest.hcl and tests/check_slack_runtime_plan.py; prove the runtime assertion fails before implementation.
- [x] T006 [US1] Explicitly select Python 3.12 in modules/cloudwatch-alarm-actions/lambda-subsciptions.tf.
- [x] T007 [US1] Add generic standalone examples/slack/ and update modules/cloudwatch-alarm-actions/README.md with runtime and verification commands.
- [x] T008 [US1] Run native Terraform plans and Python 3.12 handler regressions; wire scoped checks into .github/workflows/terraform-test.yaml.

## Phase 4: User Story 2 — account adoption validation
- [x] T009 [US2] Capture two regional live reporter configurations read-only into operator-local evidence outside the shared repository.
- [x] T010 [US2] Test the unchanged consumer-shaped dual-region Slack configuration against the candidate module; record results and the remaining versioned-release/actual consumer-plan boundary outside the shared repository.

## Phase 5: Review
- [x] T011 Review diff, formatting, generic naming and validation evidence; record generic results in specs/003-slack-runtime-upgrade/validation.md.
- [x] T012 Commit generic change, create a generic PR and record customer validation plus PR link in Jira.

## Dependencies and Strategy
T001 -> T002 -> T003 -> T004/T005 -> T006 -> T007/T008 -> T009/T010 -> T011 -> T012. US1 is independently verified by mocked Terraform plans and actual pinned-handler tests. US2 validates both regional consumer configurations and records rollout gates. T004 and T005 concern different files but execute inline; no delegated work. No production apply or real notification is part of these tasks.
