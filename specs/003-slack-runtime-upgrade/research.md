# Research

- Decision: use Python 3.12, supported on AL2023 through the projected October 31, 2028 deprecation date. Source: https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html .
- Decision: retain notify-slack 6.7.0 and explicitly pass its existing runtime input, avoiding a dependency upgrade. Source: https://github.com/terraform-aws-modules/terraform-aws-notify-slack/tree/v6.7.0 .
- Compatibility: Python 3.12 changes Unicode response serialization; SNS callers do not depend on synchronous response escaping. Source: https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html .
- Candidate scope: only Slack reporter wrapper. Unrelated Python handlers are separate work.
- No unresolved research decisions; actual production plan depends on release/adoption.
