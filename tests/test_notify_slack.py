"""Regression tests for the patched Security Hub Slack formatter."""

import importlib.util
import os
import unittest
from pathlib import Path
from unittest.mock import Mock

os.environ.setdefault("AWS_DEFAULT_REGION", "eu-central-1")
os.environ.setdefault("AWS_ACCESS_KEY_ID", "test")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "test")

SOURCE = (
    Path(__file__).resolve().parents[1]
    / "modules/cloudwatch-alarm-actions/functions/notify_slack.py"
)
spec = importlib.util.spec_from_file_location("notify_slack_under_test", SOURCE)
notify_slack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(notify_slack)


def finding_event(product_name, compliance=None):
    finding = {
        "Id": "test-finding",
        "ProductArn": "arn:aws:securityhub:eu-central-1:047719614430:product/aws/securityhub",
        "ProductName": product_name,
        "Severity": {"Label": "HIGH"},
        "Workflow": {"Status": "NEW"},
        "ProductFields": {},
        "Resources": [{"Id": "arn:aws:ec2:eu-central-1:047719614430:instance/i-test"}],
        "Title": "Controlled test finding",
    }
    if compliance is not None:
        finding["Compliance"] = {"Status": compliance}
    return {"detail": {"findings": [finding]}}


class SecurityHubFormatterTests(unittest.TestCase):
    def setUp(self):
        notify_slack.SECURITY_HUB_CLIENT = Mock()
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.return_value = {}

    def test_inspector_finding_without_compliance_formats(self):
        result = notify_slack.format_aws_security_hub(
            finding_event("Inspector"), "eu-central-1"
        )
        self.assertIn("AWS Inspector Finding", result["text"])
        self.assertIn(
            {"title": "Compliance Status", "value": "`UNKNOWN`", "short": True},
            result["fields"],
        )
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_not_called()

    def test_security_hub_finding_without_compliance_formats(self):
        result = notify_slack.format_aws_security_hub(
            finding_event("Security Hub"), "eu-central-1"
        )
        self.assertIn("AWS Security Hub Finding", result["text"])
        self.assertIn(
            {"title": "Compliance Status", "value": "`UNKNOWN`", "short": True},
            result["fields"],
        )
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_not_called()

    def test_failed_new_finding_still_marks_notified(self):
        notify_slack.format_aws_security_hub(
            finding_event("Security Hub", "FAILED"), "eu-central-1"
        )
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_called_once_with(
            FindingIdentifiers=[
                {
                    "Id": "test-finding",
                    "ProductArn": "arn:aws:securityhub:eu-central-1:047719614430:product/aws/securityhub",
                }
            ],
            Workflow={"Status": "NOTIFIED"},
        )


if __name__ == "__main__":
    unittest.main()
