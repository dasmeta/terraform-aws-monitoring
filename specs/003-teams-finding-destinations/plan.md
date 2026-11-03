# Plan

- Scope: extend the existing `finding_delivery` object and reuse the existing `cloudwatch-alarm-actions` Teams Lambda subscription. No new provider capability or standalone Teams service.
- Add locals for the two selected Teams webhook lists, append normal-stream destinations to the existing alert topic, and send urgent-stream destinations to the high-severity topic.
- Derive Teams subscription `for_each` keys from public list indexes so sensitive webhook URLs stay in values. Preserve current string index keys.
- Verify route selection with mocked Terraform tests, validate both affected modules, and check no destinations are added by default.
- Rollback: remove the new `finding_delivery` options. Previously configured legacy `alarm_actions.teams_webhooks` remain unchanged.
- Existing layout and grouped object conventions remain; every added grouped attribute gets an inline description. The AWS provider is not changed.
