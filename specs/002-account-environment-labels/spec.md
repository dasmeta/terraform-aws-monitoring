# Account-aware Security Hub environment labels

## Problem

A delegated administrator receives findings from multiple AWS accounts. Its static `environment_label` currently marks every member finding as Production, including development findings.

## Requirements

- An optional account-ID-to-environment map takes precedence over the static label for matching findings.
- Unmapped accounts retain the current static-label, resource-tag, then Unknown fallback.
- Slack, Opsgenie, paging policy, and daily summaries use the resolved environment.
- Existing grouped incident aliases remain stable when a map is added to a deployment using a static label.
- Existing stored groups are relabeled when read; a new finding event is not required.
- Mixed-account daily summaries do not claim one environment or account.
- A consumer can select environment labels whose CRITICAL non-container Inspector findings use P2 without changing other environments or the default policy.
- No customer-specific account IDs enter the reusable module.

## Acceptance

- A development member finding is displayed as Dev while a production finding remains Production.
- Existing Inspector group IDs and paging aliases do not change solely because the map is enabled.
- A mixed daily digest displays Multiple environments and Multiple accounts.
- A consumer can select Dev for P2 while Production and Root retain P1.
- With an empty map, prior behavior and tests remain valid.
