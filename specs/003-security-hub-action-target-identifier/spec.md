# Feature Specification: Configurable Security Hub Action Target Identifier

**Created**: 2026-11-06
**Status**: Implemented for review
**Input**: Allow a Security Hub findings delivery workspace to coexist with an existing account-level Security Hub action target in the same AWS account and Region.

## User scenarios and acceptance

1. An operator can set a distinct action target identifier for a second Security Hub module instance. Terraform plans and applies without `ResourceConflictException` when the first instance already owns `SendToTargets`.
2. A consumer that omits the new input keeps identifier `SendToTargets` and does not replace its existing action target.
3. Manual Security Hub actions continue to match the action target created by their own module instance.

## Requirements

- Add an optional `action_target_identifier` input to `modules/security-hub` with the existing value as its default.
- Use the input for the `aws_securityhub_action_target` identifier without changing the resource address or action target name behavior.
- Document a second-instance example and verify the default and custom identifiers in a focused Terraform test.
- Keep Security Hub hub, standards, and finding aggregator ownership unchanged.

## Success criteria

- Existing consumers have no Terraform diff from this interface addition alone.
- Buycycle can plan and apply grouped finding delivery beside its existing account module with no action target ID collision.
