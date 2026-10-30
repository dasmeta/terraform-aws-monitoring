# Stable Slack instance key for channel changes

## Problem

Changing a Slack webhook's `channel` in `modules/cloudwatch-alarm-actions` changes the `for_each` key. SPM's production plan for moving Security Hub alerts to `#project-spm-security-alerts` therefore proposes deleting the existing Slack Lambda, subscription, role, and permissions and creating replacements (11 deletes, 12 creates).

## Scope

Add an optional, non-secret `instance_key` to each `slack_webhooks` entry. When omitted, preserve the existing `<channel>-<username>` key. When set, use it as the stable Terraform instance key while allowing `channel` and `hook_url` to change. Keep the current Lambda name and resource addresses when SPM supplies the prior key.

## Acceptance criteria

- Existing callers without `instance_key` keep the same module keys.
- A caller can retain the old instance key while changing the channel and sensitive webhook URL.
- A production SPM plan changes the existing Slack Lambda configuration in place and avoids deleting its subscription or permissions solely because the channel changed.
- Terraform tests and a state-backed SPM plan pass. No production apply is part of this code change.
