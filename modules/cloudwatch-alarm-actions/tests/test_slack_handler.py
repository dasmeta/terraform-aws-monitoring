"""Exercise the installed upstream reporter with AWS and HTTP calls mocked."""

import argparse
import importlib.util
import json
import os
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs


class SlackHandlerTest(unittest.TestCase):
    handler_path = None

    def setUp(self):
        self.environment = patch.dict(os.environ, {
            "AWS_REGION": "us-east-2",
            "SLACK_WEBHOOK_URL": "https://hooks.example.com/services/test",
            "SLACK_CHANNEL": "example-monitoring",
            "SLACK_USERNAME": "reporter",
            "SLACK_EMOJI": ":warning:",
            "LOG_EVENTS": "False",
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)
        boto3 = types.ModuleType("boto3")
        boto3.client = Mock(side_effect=lambda *args, **kwargs: Mock())
        with patch.dict(sys.modules, {"boto3": boto3}):
            spec = importlib.util.spec_from_file_location("reporter_under_test", self.handler_path)
            self.handler = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.handler)
        self.transport = patch.object(self.handler.urllib.request, "urlopen")
        self.urlopen = self.transport.start()
        self.addCleanup(self.transport.stop)
        self.urlopen.return_value.getcode.return_value = 200
        self.urlopen.return_value.info.return_value.as_string.return_value = "OK"

    @staticmethod
    def event(region="us-east-2", state="ALARM"):
        message = {
            "AlarmName": "example-high-errors",
            "AlarmDescription": "Error threshold exceeded — alert",
            "AWSAccountId": "123456789012",
            "NewStateValue": state,
            "OldStateValue": "OK" if state == "ALARM" else "ALARM",
            "NewStateReason": "Threshold crossed",
        }
        return {"Records": [{"Sns": {
            "TopicArn": f"arn:aws:sns:{region}:123456789012:account-alarms-handling",
            "Subject": f"{state}: example-high-errors",
            "Message": json.dumps(message),
        }}]}

    def test_alarm_states_and_regions_preserve_destination_and_details(self):
        for region in ("us-east-2", "us-east-1"):
            for state, color in (("ALARM", "danger"), ("OK", "good"), ("INSUFFICIENT_DATA", "warning")):
                with self.subTest(region=region, state=state):
                    self.urlopen.reset_mock()
                    result = json.loads(self.handler.lambda_handler(self.event(region, state), {}))
                    self.assertEqual(result["code"], 200)
                    self.urlopen.assert_called_once()
                    request, data = self.urlopen.call_args.args
                    self.assertEqual(request.full_url, os.environ["SLACK_WEBHOOK_URL"])
                    payload = json.loads(parse_qs(data.decode())["payload"][0])
                    self.assertEqual(payload["channel"], "example-monitoring")
                    self.assertEqual(payload["username"], "reporter")
                    attachment = payload["attachments"][0]
                    self.assertEqual(attachment["color"], color)
                    fields = {item["title"]: item["value"] for item in attachment["fields"]}
                    self.assertEqual(fields["Alarm Name"], "`example-high-errors`")
                    self.assertEqual(fields["Current State"], f"`{state}`")
                    self.assertIn("region=" + region, fields["Link to Alarm"])
                    self.assertIn("—", fields["Alarm Description"])

    def test_http_failure_preserves_upstream_status_response(self):
        headers = Mock()
        headers.as_string.return_value = "rate limited"
        self.urlopen.side_effect = HTTPError("https://hooks.example.com", 429, "rate limited", headers, None)
        with self.assertLogs(level="ERROR"):
            result = json.loads(self.handler.lambda_handler(self.event(), {}))
        self.assertEqual(result["code"], 429)

    def test_transport_failure_propagates_for_lambda_retry(self):
        self.urlopen.side_effect = URLError("connection failed")
        with self.assertRaises(URLError):
            self.handler.lambda_handler(self.event(), {})

    def test_malformed_alarm_does_not_send_notification(self):
        event = self.event()
        event["Records"][0]["Sns"]["Message"] = '{"AlarmName":"incomplete"}'
        with self.assertRaises(KeyError):
            self.handler.lambda_handler(event, {})
        self.urlopen.assert_not_called()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--handler", required=True, type=Path)
    args, remaining = parser.parse_known_args()
    if not args.handler.is_file():
        parser.error("handler is missing; run terraform init -backend=false first")
    SlackHandlerTest.handler_path = args.handler.resolve()
    unittest.main(argv=[sys.argv[0], *remaining])
