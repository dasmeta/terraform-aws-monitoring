"""Security Hub Teams card and delivery failure regression tests."""

import importlib.util
import json
import os
import pathlib
import sys
import unittest
from unittest.mock import patch
from urllib.error import HTTPError


SOURCE = pathlib.Path(__file__).resolve().parents[2] / "modules" / "lambda-subscription" / "src"
sys.path.insert(0, str(SOURCE))
spec = importlib.util.spec_from_file_location("teams_lambda", SOURCE / "teams" / "lambda.py")
teams = importlib.util.module_from_spec(spec)
spec.loader.exec_module(teams)


def sns_record(message):
    return {"Sns": {"Type": "Notification", "Subject": "Security Hub", "Message": json.dumps(message)}}


class TeamsSecurityHubDeliveryTests(unittest.TestCase):
    def test_urgent_finding_card_is_concise(self):
        event = {"_dasmeta_group_urgent": True, "_dasmeta_group": {"label": "Inspector | api | sha256:abc"},
                 "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [{
                     "Title": "CVE-2026-12345 - openssl", "Severity": {"Label": "CRITICAL"},
                     "Resources": [{"Id": "arn:aws:ecr:eu-central-1:123456789012:repository/api"}],
                     "Description": "x" * 10000}]}}
        card = teams.handle_notification(sns_record(event))
        fact = card["attachments"][0]["content"]["body"][1]["items"][0]["facts"][0]["value"]
        self.assertIn("CVE-2026-12345", fact)
        self.assertIn("CRITICAL", fact)
        self.assertLess(len(fact), 2000)

    def test_webhook_rejection_raises_for_lambda_retry(self):
        event = {"Records": [sns_record({"message": "test"})]}
        error = HTTPError("https://example.com/teams", 429, "Too Many Requests", {}, None)
        with patch.dict(os.environ, {"REGION": "eu-central-1", "WEBHOOK_URL": "https://example.com/teams"}), \
             patch.object(teams, "urlopen", side_effect=error):
            with self.assertRaises(HTTPError):
                teams.handler(event, None)


if __name__ == "__main__":
    unittest.main()
