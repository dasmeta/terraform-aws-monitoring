# Tasks: GuardDuty Alert Action Text

- [x] Add a regression test for GuardDuty EC2 node metadata in immediate and grouped alert text.
- [x] Confirm the regression fails against the current formatter (it recommended patching the AMI).
- [x] Change shared action selection and grouped description guidance for GuardDuty only.
- [x] Run targeted and security-hub Python tests; inspect the diff for unrelated behavior.
- [x] Update task evidence and prepare the change for review.

## Verification evidence

- Regression failed before implementation with `Patch eks-dev/general node image ami-04e2bf742b1d6ff74`.
- Targeted test passed after implementation.
- `python3 -m unittest discover -s modules/security-hub/tests -p 'test_*.py'`: 189 tests passed.
- `git diff --check`: passed.
