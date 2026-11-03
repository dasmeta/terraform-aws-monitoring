"""Regression tests for remediation groups used by urgent finding delivery."""

import importlib.util
import hashlib
import json
import os
import pathlib
import sys
import unittest
from unittest.mock import patch


ROUTER = pathlib.Path(__file__).resolve().parents[1] / "functions" / "finding_router.py"
spec = importlib.util.spec_from_file_location("finding_router", ROUTER)
router = importlib.util.module_from_spec(spec)
spec.loader.exec_module(router)
sys.path.insert(0, str(ROUTER.parent))
import group_digest as digest


def finding(identifier, resource, product="Inspector"):
    return {
        "Id": identifier,
        "AwsAccountId": "123456789012",
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "ProductName": product,
        "Title": identifier,
        "Resources": [resource],
    }


class InspectorGroupingTests(unittest.TestCase):
    def test_existing_fallback_group_migrates_on_same_finding_timestamp(self):
        resource = {"Type": "AwsEcrContainerImage", "Id":
                    "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:" + "a" * 64}
        item = finding("CVE-1", resource)
        item.update({"CreatedAt": "2026-11-03T09:30:00Z", "UpdatedAt": "2026-11-03T09:30:00Z",
                     "RecordState": "ACTIVE", "Workflow": {"Status": "NEW"},
                     "Severity": {"Label": "CRITICAL"}})
        key = router._finding_key(item)
        old_key = hashlib.sha256("|".join((item["AwsAccountId"], "eu-central-1", "Inspector", key))
                                 .encode()).hexdigest()
        previous = router._compact_finding(item)
        previous["group"] = {**previous["group"], "key": old_key, "label": "Inspector | CVE-1"}

        class Table:
            request = None

            def update_item(self, **kwargs):
                self.request = kwargs

        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test-table"}), \
             patch.object(router, "_get_item", return_value={"notification_updated_at": item["UpdatedAt"],
                          "notification_payload": json.dumps(previous), "notification_pending": "0",
                          "notification_state": "ACTIVE"}):
            self.assertTrue(router._record_grouped(table, item))
        values = table.request["ExpressionAttributeValues"]
        updated = json.loads(values[":payload"]["S"])
        self.assertEqual(updated["previous_group_key"], old_key)
        self.assertTrue(updated["migration_brief_pending"])
        self.assertEqual(updated["group"]["label"], "Inspector | api | sha256:aaaaaaaaaaaa")
        self.assertEqual(values[":pending"]["S"], "1")

    def test_urgent_reconciliation_skips_same_priority_update(self):
        summary = {"group": {"key": "new-group", "product": "Inspector"}, "priority": "P1",
                   "urgent_signature": "signature", "active_count": 2}
        with patch.object(digest, "_ops_action") as action, \
             patch.object(digest, "_set_fields"), \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"):
            digest.sync_opsgenie(object(), summary, {"urgent_state": "SENT"}, 1793698200)
        self.assertFalse(any("/priority?" in call.args[1] for call in action.call_args_list))

    def test_superseded_group_closes_after_replacement_opens(self):
        groups = {"new-group": [{"previous_group_key": "old-group"}]}
        def get_item(_table, key):
            return {"opsgenie_open": "1"} if key == "group#new-group" else {"urgent_state": "SENT"}
        with patch.object(digest, "_get_item", side_effect=get_item), \
             patch.object(digest, "_ops_action") as action, \
             patch.object(digest, "_set_fields") as set_fields:
            self.assertEqual(digest.migrate_previous_groups(object(), groups), 1)
        self.assertIn("securityhub-group-old-group/close", action.call_args.args[1])
        self.assertEqual(set_fields.call_args.args[1], "group#old-group")

    def test_migration_triggers_one_slack_brief_until_acknowledged(self):
        record = {"previous_group_key": "old-group", "migration_brief_pending": True, "pending": True}
        self.assertTrue(digest._migration_slack_due({"new-group": [record]}))
        record["pending"] = False
        self.assertFalse(digest._migration_slack_due({"new-group": [record]}))
        record["pending"] = True
        record.pop("migration_brief_pending")
        self.assertFalse(digest._migration_slack_due({"new-group": [record]}))

    def test_ec2_cves_on_same_instance_share_group(self):
        resource = {"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-1",
                    "Details": {"AwsEc2Instance": {"ImageId": "ami-1"}}}
        first = router._group_identity(finding("CVE-1", resource))
        second = router._group_identity(finding("CVE-2", resource))
        self.assertEqual(first["key"], second["key"])
        self.assertIn("i-1", first["label"])

    def test_ecr_cves_share_image_digest_but_not_repository(self):
        def image(repo, digest):
            return {"Type": "AwsEcrContainerImage", "Id": f"arn:aws:ecr:eu-central-1:123456789012:repository/{repo}",
                    "Details": {"AwsEcrContainerImage": {"RepositoryName": repo, "ImageDigest": digest}}}
        first = router._group_identity(finding("CVE-1", image("api", "sha256:aaa")))
        self.assertEqual(first["key"], router._group_identity(finding("CVE-2", image("api", "sha256:aaa")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-3", image("api", "sha256:bbb")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-4", image("web", "sha256:aaa")))["key"])

    def test_ecr_image_id_without_details_shares_group(self):
        image_id = "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:" + "a" * 64
        resource = {"Type": "AwsEcrContainerImage", "Id": image_id}
        self.assertEqual(router._group_identity(finding("CVE-1", resource))["key"],
                         router._group_identity(finding("CVE-2", resource))["key"])

    def test_ecr_cves_publish_one_urgent_claim_per_image(self):
        resource = {"Type": "AwsEcrContainerImage", "Id":
                    "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:" + "a" * 64}
        findings = [finding("CVE-1", resource), finding("CVE-2", resource)]
        for item in findings:
            item.update({"CreatedAt": "2026-11-03T09:30:00Z", "UpdatedAt": "2026-11-03T09:30:00Z",
                         "RecordState": "ACTIVE", "Workflow": {"Status": "NEW"},
                         "Severity": {"Label": "CRITICAL"}})
        by_key = {router._finding_key(item): item for item in findings}
        published = set()

        class Table:
            def update_item(self, **_kwargs):
                pass

        def get_item(_table, key):
            item = by_key[key]
            return {"notification_updated_at": item["UpdatedAt"], "notification_state": "ACTIVE",
                    "notification_payload": json.dumps({"group": router._group_identity(item)})}

        def publish_once(_table, _sns, key, destination, *_args):
            identity = (key, destination)
            if identity in published:
                return False
            published.add(identity)
            return True

        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": findings}}
        env = {"FINDING_CUTOVER_AT": "2026-11-03T08:30:00Z", "GROUPED_DELIVERY_MODE": "true",
               "HIGH_TOPIC_ARN": "high-topic", "SLACK_TOPIC_ARN": "slack-topic", "DELIVERY_TABLE_NAME": "test-table"}
        with patch.dict(os.environ, env), patch.object(router, "_record_grouped", return_value=True), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_publish_once", side_effect=publish_once):
            counts = router.route_event(event, Table(), object(), now=1793698200)
        self.assertEqual(counts, {"recorded": 2, "urgent": 1, "urgent_slack": 1, "skipped": 0})

    def test_lambda_cves_share_resource(self):
        resource = {"Type": "AwsLambdaFunction", "Id": "arn:aws:lambda:eu-central-1:123456789012:function:worker:3"}
        self.assertEqual(router._group_identity(finding("CVE-1", resource))["key"],
                         router._group_identity(finding("CVE-2", resource))["key"])

    def test_missing_target_keeps_finding_specific_group(self):
        resource = {"Type": "AwsEcrContainerImage", "Id": "arn:aws:ecr:eu-central-1:123456789012:repository/api"}
        self.assertNotEqual(router._group_identity(finding("CVE-1", resource))["key"],
                            router._group_identity(finding("CVE-2", resource))["key"])

    def test_non_inspector_grouping_is_unchanged(self):
        resource = {"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-1"}
        self.assertNotEqual(router._group_identity(finding("control-1", resource, "Security Hub"))["key"],
                            router._group_identity(finding("control-2", resource, "Security Hub"))["key"])


if __name__ == "__main__":
    unittest.main()
