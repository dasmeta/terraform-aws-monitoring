# Slack reporter contract

The existing wrapper exposes no new input. The runtime selection is python3.12. Handler remains notify_slack.lambda_handler. SNS permissions, subscription endpoint and function naming remain unchanged. Tests process SNS Records containing JSON CloudWatch AlarmName, NewStateValue, NewStateReason, OldStateValue, AlarmDescription and AWSAccountId; region is derived from Sns.TopicArn. HTTP delivery is mocked.
