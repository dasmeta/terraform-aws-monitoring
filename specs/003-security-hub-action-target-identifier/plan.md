# Implementation Plan: Security Hub Action Target Identifier

## Current state and gap

The published `dasmeta/monitoring/aws//modules/security-hub` v3.2.0 always creates `aws_securityhub_action_target.sec-hub-target` with identifier `SendToTargets`. Buycycle already has that identifier under its account module. A second module instance planned 95 additions and no changes or deletions, but apply stopped at this collision after creating 82 resources.

## Design

Add a flat string input `action_target_identifier` adjacent to `action_target_name`, defaulting to `SendToTargets`. The action target resource uses the new input for `identifier`. The existing EventBridge pattern uses the managed target's name and ARN, so no routing expression changes are required. The input is part of the existing module interface; no new provider capability or wrapper is needed.

## Files

- `modules/security-hub/variables.tf`: new backward-compatible input and validation for a nonempty identifier.
- `modules/security-hub/main.tf`: use the input in the action target resource.
- `modules/security-hub/README.md` and a focused example/test: show a distinct identifier for a second instance and verify the default.

## Compatibility and impact

The default preserves current state and avoids replacement for all existing consumers. A consumer setting a new identifier deliberately creates a different action target; this is appropriate for a new module instance and should be reviewed before changing a deployed instance. No change to existing hub, standards, aggregator, or alert routing inputs. The DasMeta module repository is the downstream governance surface; no shared constitution rule changes are proposed.

## Validation and delivery

Run `terraform fmt -check`, `terraform init -backend=false`, `terraform validate`, and a focused native test or equivalent fixture. Review the diff and create an upstream PR. A published release is required before the Buycycle YAML can use the new input through the registry module. The Buycycle rollout then sets a unique identifier, plans the remaining resources, and applies only that workspace. Rollback is to stop new delivery, then destroy its new resources using its own workspace plan; the existing action target remains owned by the account workspace.

## Gate and baseline

This spec, plan, and tasks package supplies the repository's Speckit evidence for the module change. Existing layout and examples are retained; unrelated baseline gaps are outside this bounded fix.
