# Verification

From modules/cloudwatch-alarm-actions:

```sh
terraform init -backend=false -input=false
terraform validate
terraform test -filter=tests/slack_runtime.tftest.hcl -json -verbose > /tmp/slack-runtime-tests.jsonl
python3 tests/check_slack_runtime_plan.py /tmp/slack-runtime-tests.jsonl
python3.12 tests/test_slack_handler.py --handler .terraform/modules/notify_slack/functions/notify_slack.py
```

All cloud interactions in native tests are mocked. Runtime handler tests mock the webhook transport. This does not deploy or notify.
