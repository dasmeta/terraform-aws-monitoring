# Teams destinations for Security Hub finding delivery

## User need

An operator can send Security Hub notifications to a Microsoft Teams webhook using the normal Slack stream, the urgent Opsgenie stream, or both, while keeping the current Slack and Opsgenie behavior.

## Requirements

- Add an optional webhook list and destination selection (`none`, `slack`, `opsgenie`, `both`) to grouped finding delivery. Default to no new Teams subscriptions.
- `slack` subscribes Teams to the normal finding topic, including digest and urgent messages. `opsgenie` subscribes Teams to the high-severity topic. `both` subscribes to both topics.
- Require a nonempty Teams webhook list when a destination is selected; reject unused webhook lists and unsupported modes.
- Preserve existing `alarm_actions.teams_webhooks` behavior and its Terraform resource addresses.
- Accept sensitive Teams webhook values without exposing them in Terraform `for_each` keys.
- Document that `both` sends an urgent event through both topics, so one webhook receives two urgent messages.

## Acceptance

Routing tests cover all four modes, empty and sensitive webhook inputs, and unchanged legacy Teams subscriptions. Existing users without the new options have no new Teams resources.
