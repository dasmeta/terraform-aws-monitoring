"""Verify actual planned Lambda resources from terraform test -json -verbose."""

import json
from pathlib import Path
import sys


def verify(path):
    expected = {
        "primary_reporter": "example-monitoring-reporter-slack",
        "secondary_reporter": "example-monitoring-reporter-virginia-slack",
    }
    topics = {
        "primary_reporter": "arn:aws:sns:us-east-2:123456789012:account-alarms-handling",
        "secondary_reporter": "arn:aws:sns:us-east-1:123456789012:account-alarms-handling-virginia",
    }
    checked = set()
    summary = None
    for line in Path(path).read_text().splitlines():
        event = json.loads(line)
        if event.get("type") == "test_summary":
            summary = event["test_summary"]
        if event.get("type") != "test_plan":
            continue
        run = event.get("@testrun")
        if run not in expected:
            continue
        changes = event["test_plan"]["resource_changes"]
        functions = [change["change"]["after"] for change in changes if change["type"] == "aws_lambda_function"]
        assert len(functions) == 1, f"{run}: expected exactly one reporter"
        function = functions[0]
        assert function["runtime"] == "python3.12", f"{run}: runtime is {function['runtime']}"
        assert function["handler"] == "notify_slack.lambda_handler", f"{run}: handler changed"
        assert function["function_name"] == expected[run], f"{run}: function identity changed"
        subscriptions = [change["change"]["after"] for change in changes if change["type"] == "aws_sns_topic_subscription"]
        lambda_subscriptions = [item for item in subscriptions if item["protocol"] == "lambda"]
        assert len(lambda_subscriptions) == 1, f"{run}: expected one SNS-to-Lambda subscription"
        assert lambda_subscriptions[0]["topic_arn"] == topics[run], f"{run}: reporter SNS topic changed"
        permissions = [change["change"]["after"] for change in changes if change["type"] == "aws_lambda_permission"]
        unqualified = [item for item in permissions if item.get("qualifier") is None]
        assert unqualified, f"{run}: missing unqualified SNS invocation permission"
        for permission in permissions:
            assert permission["function_name"] == expected[run], f"{run}: permission targets a different function"
            assert permission["principal"] == "sns.amazonaws.com", f"{run}: SNS principal changed"
            assert permission["action"] == "lambda:InvokeFunction", f"{run}: SNS action changed"
            assert permission["source_arn"] == topics[run], f"{run}: SNS permission source changed"
        assert any(item["protocol"] == "https" and item["endpoint"] == "https://alerts.example.com/webhook" for item in subscriptions), f"{run}: unrelated HTTPS subscription changed"
        checked.add(run)
    assert summary and summary["status"] == "pass" and summary["passed"] == 2, f"Terraform tests did not pass: {summary}"
    assert checked == set(expected), f"Missing plans: {set(expected) - checked}"
    print("Both regional plans use Python 3.12 and retain reporter identities, handler and subscription types.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: check_slack_runtime_plan.py terraform-test.jsonl")
    verify(sys.argv[1])
