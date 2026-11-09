# Tasks: Consistent notification package creation

## Setup

- [x] T001 Confirm main baseline, release workflow, and dependency constraints in package.json and modules/cloudwatch-alarm-actions/modules/lambda-subscription/main.tf.
- [x] T002 Record the clean-run reproduction and chosen dependency in specs/002-teams-package-consistency/research.md.

## User Story 1: Clean and repeated notification deployment

- [x] T003 [US1] Add the real filesystem regression in modules/cloudwatch-alarm-actions/tests/test_package_consistency.py and the two-instance native compatibility test; observe the filesystem regression fail before changing the module.
- [x] T004 [US1] Gate the local package filename on the computed archive size in modules/cloudwatch-alarm-actions/modules/lambda-subscription/main.tf.
- [x] T005 [US1] Verify clean and repeated applies using modules/cloudwatch-alarm-actions/tests/teams_package_consistency.tftest.hcl, then existing sensitive_teams and slack_package_uniqueness tests.
- [x] T006 [US1] Document clean-run packaging and validation in modules/cloudwatch-alarm-actions/README.md.

## Delivery

- [x] T007 Run scoped validation, formatting, review, and diff checks; record evidence in specs/002-teams-package-consistency/plan.md.
- [ ] T008 Commit the bounded fix and create its reviewed PR in dasmeta/terraform-aws-monitoring.
- [ ] T009 Observe the actual semantic-release result after merge and update the downstream source YAML to the published patch version.

## Dependencies and implementation strategy

T003 precedes T004; T004 precedes T005. Documentation can be completed independently after the regression behavior is established. Finish verification before publishing. Merge and release follow review; downstream pinning follows verified publication. No cloud apply is included.
