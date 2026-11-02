import importlib.util
import os
import pathlib
import sys
import unittest
import urllib.error
from unittest.mock import patch


SOURCE = pathlib.Path(__file__).parents[1] / "modules/security-hub/functions/opsgenie_notifier.py"
sys.path.insert(0, str(SOURCE.parent))
SPEC = importlib.util.spec_from_file_location("opsgenie_notifier", SOURCE)
NOTIFIER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NOTIFIER)


def finding(identifier):
    return {
        "Id": identifier,
        "AwsAccountId": "111122223333",
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "GeneratorId": "same-generator",
        "ProductName": "Inspector",
        "Severity": {"Label": "HIGH"},
        "Title": "A" * 200,
        "Description": "Finding description",
    }


class NotifierTests(unittest.TestCase):
    def test_distinct_findings_have_distinct_aliases_and_bounded_title(self):
        with patch.dict(os.environ, {"OPSGENIE_ALERT_PREFIX": "Example"}):
            first = finding("one")
            second = finding("two")
            self.assertNotEqual(NOTIFIER.finding_alias(first), NOTIFIER.finding_alias(second))
            self.assertEqual(len(NOTIFIER.alert_message(first)), 130)
            self.assertTrue(NOTIFIER.alert_message(first).startswith("Example | HIGH | Inspector | "))

    def test_create_and_close_use_same_alias_and_confirm_async_result(self):
        item = finding("one")
        event = {"detail": {"findings": [item]}}
        calls = []

        def request(method, path, payload=None):
            calls.append((method, path, payload))
            if method == "GET":
                return {"data": {"isSuccess": True}}
            return {"requestId": "request-1"}

        with patch.object(NOTIFIER, "_request", side_effect=request), patch.dict(os.environ, {"OPSGENIE_ALERT_PREFIX": "Example"}):
            NOTIFIER.deliver(event)
            NOTIFIER.deliver({**event, "_dasmeta_opsgenie_action": "close"})
        self.assertEqual(calls[0][2]["alias"], NOTIFIER.finding_alias(item))
        self.assertEqual(calls[0][2]["priority"], "P2")
        self.assertIn(NOTIFIER.finding_alias(item), calls[2][1])
        self.assertEqual(calls[2][0], "POST")

    def test_async_rejection_fails_delivery(self):
        with patch.object(NOTIFIER, "_request", side_effect=[{"requestId": "request-1"}, {"data": {"isSuccess": False, "status": "Rejected"}}]):
            with self.assertRaisesRegex(RuntimeError, "Rejected"):
                NOTIFIER.deliver({"detail": {"findings": [finding("one")]}})

    def test_urgent_group_uses_shared_alias_and_p1(self):
        item = finding("one")
        item.update({
            "Resources": [{
                "Type": "AwsEc2Instance",
                "Id": "arn:aws:ec2:eu-central-1:111122223333:instance/i-one",
                "Tags": {"kubernetes.io/cluster/example-prod": "owned", "karpenter.sh/nodepool": "general"},
                "Details": {"AwsEc2Instance": {"ImageId": "ami-123"}},
            }],
        })
        calls = []

        def request(method, path, payload=None):
            calls.append((method, path, payload))
            if method == "GET" and "identifierType=alias" in path:
                raise urllib.error.HTTPError(path, 404, "missing", {}, None)
            if method == "GET":
                return {"data": {"isSuccess": True}}
            return {"requestId": "request-1"}

        with patch.object(NOTIFIER, "_request", side_effect=request):
            NOTIFIER.deliver({"detail": {"findings": [item]}, "_dasmeta_group_urgent": True})
        self.assertTrue(calls[1][2]["alias"].startswith("securityhub-group-"))
        self.assertEqual(calls[1][2]["priority"], "P1")

    def test_urgent_group_escalates_existing_p2_without_second_alert(self):
        calls = []

        def request(method, path, payload=None):
            calls.append((method, path, payload))
            if method == "GET" and "identifierType=alias" in path:
                return {"data": {"priority": "P2"}}
            if method == "GET":
                return {"data": {"isSuccess": True}}
            return {"requestId": "request-1"}

        with patch.object(NOTIFIER, "_request", side_effect=request):
            NOTIFIER.deliver({"detail": {"findings": [finding("one")]}, "_dasmeta_group_urgent": True})
        self.assertEqual(calls[1][0], "PUT")
        self.assertIn("/priority?", calls[1][1])
        self.assertFalse(any(method == "POST" and path == "/v2/alerts" for method, path, _ in calls))


if __name__ == "__main__":
    unittest.main()
