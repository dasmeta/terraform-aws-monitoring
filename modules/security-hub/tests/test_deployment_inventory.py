"""Running-pod inventory determines only the displayed ECR environment."""

import io
import json
import os
import pathlib
import sys
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "functions"))
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")

import deployment_inventory as inventory
import finding_router as router
import group_digest as digest


ACCOUNT = "123456789012"
HASH = "a" * 64
RESOURCE = f"arn:aws:ecr:eu-central-1:{ACCOUNT}:repository/sample-api/sha256:{HASH}"
CONFIG = {"bucket": "test-inventory", "key": "running-pods.json", "max_age_seconds": 900,
          "required_clusters": ["eks-dev-stage", "eks-prod2"]}


class S3:
    def __init__(self, body):
        self.body = body

    def get_object(self, **kwargs):
        return {"Body": io.BytesIO(json.dumps(self.body).encode())}


def snapshot(now, environments=("dev", "prod"), clusters=None):
    return {"observed_at": now.isoformat(),
            "clusters": clusters if clusters is not None else CONFIG["required_clusters"],
            "images": [{"account": ACCOUNT, "region": "eu-central-1", "repository": "sample-api",
                        "digest": "sha256:" + HASH, "environment": env} for env in environments]}


def finding():
    return {"Id": "finding-one", "AwsAccountId": ACCOUNT,
            "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector", "ProductName": "Inspector",
            "Title": "CVE-2026-1 - sample", "CreatedAt": "2026-11-09T08:00:00Z",
            "UpdatedAt": "2026-11-09T08:01:00Z", "RecordState": "ACTIVE",
            "Workflow": {"Status": "NEW"}, "Severity": {"Label": "CRITICAL"},
            "Resources": [{"Type": "AwsEcrContainerImage", "Id": RESOURCE,
                           "Details": {"AwsEcrContainerImage": {"RepositoryName": "sample-api", "ImageDigest": "sha256:" + HASH}}}],
            "Vulnerabilities": [{"Id": "CVE-2026-1", "ExploitAvailable": "NO"}]}


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime.now(timezone.utc)
        self.config = patch.dict(os.environ, DEPLOYMENT_INVENTORY_CONFIG=json.dumps(CONFIG))
        self.config.start()
        self.addCleanup(self.config.stop)

    def test_multi_environment_display_preserves_incident_identity_and_priority(self):
        loaded = inventory.load_inventory(S3(snapshot(self.now)), now=self.now)
        record = router._compact_finding(finding())
        plain = digest.summarize_group([record], identity="page_group")
        enriched = digest.summarize_group([record], identity="page_group", inventory=loaded)
        self.assertEqual(enriched["environment"], "dev, prod")
        self.assertEqual(enriched["group"]["key"], plain["group"]["key"])
        self.assertEqual(enriched["priority"], plain["priority"])
        self.assertIn("Environment: dev, prod", digest._opsgenie_description(enriched))
        self.assertEqual(digest._slack_payload(enriched, False)["_dasmeta_group_digest"]["environment"], "dev, prod")

    def test_no_match_requires_complete_fresh_snapshot(self):
        record = {"resource": RESOURCE}
        loaded = inventory.load_inventory(S3(snapshot(self.now, environments=())), now=self.now)
        self.assertEqual(inventory.displayed_environment([record], loaded, now=self.now), "No running workload found")
        incomplete = inventory.load_inventory(S3(snapshot(self.now, environments=(), clusters=["eks-prod2"])), now=self.now)
        self.assertEqual(inventory.displayed_environment([record], incomplete, now=self.now), "Unverified")
        stale = inventory.load_inventory(S3(snapshot(self.now - timedelta(minutes=20), environments=())), now=self.now)
        self.assertEqual(inventory.displayed_environment([record], stale, now=self.now), "Unverified")

    def test_same_digest_in_other_repository_is_not_a_match(self):
        data = snapshot(self.now)
        data["images"][0]["repository"] = "other-api"
        data["images"][1]["repository"] = "other-api"
        loaded = inventory.load_inventory(S3(data), now=self.now)
        self.assertEqual(inventory.displayed_environment([{"resource": RESOURCE}], loaded, now=self.now),
                         "No running workload found")

    def test_environment_change_updates_existing_incident_without_reopening(self):
        loaded = inventory.load_inventory(S3(snapshot(self.now)), now=self.now)
        summary = digest.summarize_group([router._compact_finding(finding())],
                                         identity="page_group", inventory=loaded)
        state = {"opsgenie_open": "1", "opsgenie_priority": summary["priority"],
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": summary["urgent_signature"],
                 "opsgenie_active_count": str(summary["active_count"]),
                 "opsgenie_display_environment": "Unverified"}
        with patch.object(digest, "_ops_action") as action, patch.object(digest, "_set_fields") as update:
            digest.sync_opsgenie(object(), summary, state, int(self.now.timestamp()))
        paths = [call.args[1] for call in action.call_args_list]
        self.assertTrue(any("/description?" in path for path in paths))
        self.assertFalse(any(path == "/v2/alerts" for path in paths))
        self.assertTrue(any(call.args[2].get("opsgenie_display_environment") == "dev, prod"
                            for call in update.call_args_list))


if __name__ == "__main__":
    unittest.main()
