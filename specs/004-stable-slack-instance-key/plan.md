# Plan

## Design

Extend the `slack_webhooks` object type with `instance_key = optional(string)`. In the wrapper's local key expression, use `coalesce(webhook.instance_key, "${webhook.channel}-${webhook.username}")`. The value is an identity label, not a secret or destination. Preserve the existing default identity and the sensitive URL handling from PR #106.

SPM will set `instance_key: proejct-spm-monitoring-security-hub` while changing `channel` to `project-spm-security-alerts` and `hook_url` to the dedicated root secret. This retains the current Terraform module instance and Lambda name. The legacy name remains until a separate reviewed migration is needed.

## Verification and safety

Add a Terraform test for the explicit stable key and retain the existing default-key test. Run targeted module tests, formatting, a clean consumer validation, and an HCP production plan. The plan should contain in-place updates rather than old/new Slack module instances. No new provider feature or version change is required. A production apply remains a separate approval gate.
