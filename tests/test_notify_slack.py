"""Regression tests for the patched Security Hub Slack formatter."""

import importlib.util
import os
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

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
        "ProductArn": "arn:aws:securityhub:eu-central-1:111122223333:product/aws/securityhub",
        "ProductName": product_name,
        "Severity": {"Label": "HIGH"},
        "Workflow": {"Status": "NEW"},
        "ProductFields": {},
        "Resources": [{"Id": "arn:aws:ec2:eu-central-1:111122223333:instance/i-test"}],
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
                    "ProductArn": "arn:aws:securityhub:eu-central-1:111122223333:product/aws/securityhub",
                }
            ],
            Workflow={"Status": "NOTIFIED"},
        )

    def test_first_delivery_router_does_not_change_workflow(self):
        routed = finding_event("Security Hub", "FAILED")
        routed["_dasmeta_first_delivery"] = True
        notify_slack.format_aws_security_hub(routed, "eu-central-1")
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_not_called()

    def test_other_security_product_receives_readable_slack_message(self):
        imported = finding_event("GuardDuty")
        finding = imported["detail"]["findings"][0]
        finding.pop("ProductFields")
        finding.pop("Resources")
        result = notify_slack.format_aws_security_hub(imported, "eu-central-1")
        self.assertIn("GuardDuty", result["text"])
        self.assertIn("AWS GuardDuty Finding", result["text"])
        self.assertIn({"title": "Severity", "value": "`HIGH`", "short": True}, result["fields"])

    def test_resolution_formats_without_mutating_finding(self):
        routed = finding_event("Inspector")
        routed["_dasmeta_resolution_delivery"] = "RESOLVED"
        result = notify_slack.format_aws_security_hub(routed, "eu-central-1")
        self.assertIn("resolved", result["text"])
        self.assertIn({"title": "Status", "value": "RESOLVED", "short": True}, result["fields"])
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_not_called()

    def test_group_digest_shows_totals_and_link_without_marking_findings_notified(self):
        message = {"_dasmeta_group_digest": {
            "label": "Inspector | example-prod/general | ami-123",
            "new_count": 24,
            "new_severities": {"HIGH": 23, "CRITICAL": 1},
            "active_count": 8,
            "active_severities": {"HIGH": 7, "CRITICAL": 1},
            "affected_resources": 2,
            "vulnerability_count": 4,
            "top_titles": [["CVE-2026-56855", 8]],
            "sample_new_ids": ["finding-one"],
            "finding_url": "https://console.aws.amazon.com/securityhub/home?region=eu-central-1#/findings",
            "closing": False,
        }}
        result = notify_slack.parse_notification(message, "Security Hub finding digest", "eu-central-1")
        self.assertIn("example-prod/general", result["text"])
        self.assertIn("24", result["fields"][0]["value"])
        self.assertEqual(result["color"], "danger")
        notify_slack.SECURITY_HUB_CLIENT.batch_update_findings.assert_not_called()

    def test_failed_slack_delivery_raises_for_retry_and_dead_letter_capture(self):
        event = {"Records": [{"Sns": {
            "Subject": "Security Hub finding digest",
            "Message": '{"text":"digest"}',
            "TopicArn": "arn:aws:sns:eu-central-1:111122223333:security",
        }}]}
        with patch.object(notify_slack, "send_slack_notification", return_value='{"code":429,"info":"rate limited"}'), patch.dict(os.environ, {"SLACK_CHANNEL": "security", "SLACK_USERNAME": "security", "SLACK_EMOJI": ":shield:"}):
            with self.assertRaisesRegex(RuntimeError, "rate limited"):
                notify_slack.lambda_handler(event, {})

    def test_daily_brief_shows_actionable_and_routine_without_finding_ids(self):
        message = {"_dasmeta_group_digest": {
            "digest_kind": "daily", "new_count": 3, "new_severities": {"HIGH": 1, "MEDIUM": 2},
            "routine_count": 268, "groups_cleared_total": 1,
            "groups_changed": [{"label": "Inspector | cluster/pool | ami-123", "new": 3, "active": 4}],
            "groups_changed_total": 1,
            "finding_url": "https://console.aws.amazon.com/securityhub/home?region=eu-central-1#/findings",
            "active_count": 4, "active_severities": {"HIGH": 2, "MEDIUM": 2},
            "affected_resources": 2, "vulnerability_count": 2, "top_titles": [],
            "sample_new_ids": ["finding-one"], "closing": False, "label": "Security Hub daily brief",
        }}
        result = notify_slack.parse_notification(message, "Security Hub finding digest", "eu-central-1")
        self.assertIn("3 actionable, 268 routine", result["text"])
        self.assertNotIn("finding-one", str(result))
        self.assertIn("Top remediation groups", [field["title"] for field in result["fields"]])

    def test_urgent_group_notification_names_remediation_target(self):
        finding = {"Title": "CVE-2026-56855", "Severity": {"Label": "CRITICAL"}}
        message = {"_dasmeta_group_urgent": True, "_dasmeta_group": {
            "label": "Inspector | cluster/pool | ami-123", "region": "eu-central-1",
        }, "detail": {"findings": [finding]}}
        result = notify_slack.parse_notification(message, "Security Hub finding", "eu-central-1")
        self.assertIn("Urgent CRITICAL", result["text"])
        self.assertIn("ami-123", str(result["fields"]))


if __name__ == "__main__":
    unittest.main()
