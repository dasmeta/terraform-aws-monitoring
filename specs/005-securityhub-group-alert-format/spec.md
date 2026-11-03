# Consistent grouped Security Hub Opsgenie alerts

## Problem

Node-image groups receive a clear patch action, while ECR image groups receive a first-CVE title with a long digest. The immediate notifier and scheduled digest build titles and descriptions separately. Opsgenie ChatOps may show the initial description even after the digest enriches the alert, so both stages need an actionable format. The digest also renders severity counts as a Python dictionary.

## Requirements

- Use a stable remediation-group action in both immediate and digest alerts. Keep the existing node-image action; identify ECR image and EC2 instance/image groups without using the first CVE as the title.
- Keep the message within Opsgenie's 130-character limit and preserve the existing group alias, priority, tags, and delivery behavior.
- Make initial and enriched descriptions useful on their own, with remediation target, resource, finding or aggregate context, and Security Hub link.
- Format severity counts as readable text. Reformat existing open grouped alerts once without creating new alerts or changing priority.

## Acceptance

- Tests cover node-image, ECR, EC2, and fallback titles; immediate and digest titles match for the same group.
- An existing open alert gets a silent message/description update after format-version change.
- Python tests and Terraform validation pass; an existing consumer plan contains only expected code and module-source/tag updates.
