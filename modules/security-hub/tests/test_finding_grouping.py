"""Regression tests for remediation groups used by urgent finding delivery."""

import importlib.util
import hashlib
import json
import os
import pathlib
import sys
import unittest
import urllib.error
from unittest.mock import patch


ROUTER = pathlib.Path(__file__).resolve().parents[1] / "functions" / "finding_router.py"
sys.path.insert(0, str(ROUTER.parent))
spec = importlib.util.spec_from_file_location("finding_router", ROUTER)
router = importlib.util.module_from_spec(spec)
spec.loader.exec_module(router)
import group_digest as digest
import group_alert_format as alert_format
import opsgenie_notifier as notifier


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
    def test_group_titles_are_stable_and_actionable(self):
        cases = [
            ({"label": "Inspector | example-cluster/workers | ami-123", "product": "Inspector",
              "cluster": "example-cluster", "nodepool": "workers", "image": "ami-123"},
             "Example Security P1: Patch example-cluster/workers node image ami-123"),
            ({"label": "Inspector | example-api | sha256:abcdef123456", "product": "Inspector"},
             "Example Security P1: Patch container image example-api@sha256:abcdef123456"),
            ({"label": "Inspector | i-123 | ami-456", "product": "Inspector"},
             "Example Security P1: Patch EC2 instance i-123 image ami-456"),
            ({"label": "Custom | Check encryption", "product": "Custom"},
             "Example Security P1: Investigate Custom | Check encryption"),
        ]
        for group, expected in cases:
            with self.subTest(group=group["label"]):
                prefix = "Example"
                self.assertEqual(alert_format.group_message(group, prefix, "P1"), expected)
                with patch.dict(os.environ, {"OPSGENIE_ALERT_PREFIX": prefix}):
                    self.assertEqual(digest._opsgenie_message({"group": group, "priority": "P1"}), expected)

    def test_immediate_alert_uses_same_group_title_and_useful_description(self):
        group = {"key": "test", "label": "Inspector | api | sha256:abcdef123456", "product": "Inspector",
                 "account": "123456789012", "region": "eu-central-1", "cluster": "", "nodepool": "", "image": ""}
        item = finding("CVE-123", {"Id": "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:abcdef"})
        requests = []
        def request(method, path, payload=None):
            requests.append((method, path, payload))
            return {"data": None} if method == "GET" else {"requestId": "confirmed"}
        with patch.dict(os.environ, {"OPSGENIE_ALERT_PREFIX": "Example"}), \
             patch.object(notifier, "_request", side_effect=request), \
             patch.object(notifier, "_wait_for_request"):
            notifier.deliver({"detail": {"findings": [item]}, "_dasmeta_group_urgent": True, "_dasmeta_group": group})
        created = next(payload for method, path, payload in requests if method == "POST" and path == "/v2/alerts")
        self.assertEqual(created["message"], alert_format.group_message(group, "Example", "P1"))
        self.assertIn("Remediation target: Inspector | api | sha256:abcdef123456", created["description"])
        self.assertIn("Finding: CVE-123", created["description"])
        self.assertNotIn("Finding ID:", created["description"])
        self.assertIn("Security Hub: https://", created["description"])

    def test_digest_description_uses_readable_severity_counts(self):
        group = {"label": "Inspector | api | sha256:abcdef123456", "product": "Inspector", "region": "eu-central-1"}
        summary = {"group": group, "urgent_vulnerability_ids": ["CVE-123"], "urgent_titles": [],
                   "urgent_count": 2, "high_count": 5, "high_severities": {"CRITICAL": 1, "HIGH": 4},
                   "affected_resources": 1, "sample_resource": "arn:aws:ecr:eu-central-1:123456789012:repository/api"}
        description = digest._opsgenie_description(summary)
        self.assertIn("HIGH/CRITICAL findings: 5 (CRITICAL 1, HIGH 4)", description)
        self.assertIn("Action: Patch container image api@sha256:abcdef123456", description)
        self.assertNotIn("{'CRITICAL'", description)

    def test_existing_alert_reformats_without_creating_another(self):
        summary = {"group": {"key": "test", "product": "Inspector"}, "priority": "P1",
                   "urgent_signature": "same", "active_count": 2}
        state = {"opsgenie_open": "1", "opsgenie_priority": "P1", "opsgenie_format_version": "2",
                 "opsgenie_urgent_signature": "same", "opsgenie_last_update_at": "2026-11-03T11:00:00Z"}
        with patch.object(digest, "_ops_action") as action, patch.object(digest, "_set_fields"), \
             patch.object(digest, "_opsgenie_message", return_value="new title"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="new description"):
            digest.sync_opsgenie(object(), summary, state, 1793703600)
        paths = [call.args[1] for call in action.call_args_list]
        self.assertNotIn("/v2/alerts", paths)
        self.assertTrue(any("/message?" in path for path in paths))
        self.assertTrue(any("/description?" in path for path in paths))

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
        self.assertEqual(updated["group"]["label"], "Inspector | api | unknown vulnerability / unknown package")
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

    def test_partial_enrichment_retries_without_recreating_alert(self):
        summary = {"group": {"key": "group", "product": "Inspector"}, "priority": "P1",
                   "urgent_signature": "signature", "active_count": 2}
        with patch.object(digest, "_ops_action", side_effect=[None, RuntimeError("update failed")]), \
             patch.object(digest, "_set_fields") as set_fields, \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"):
            with self.assertRaisesRegex(RuntimeError, "update failed"):
                digest.sync_opsgenie(object(), summary, {"urgent_state": "SENT"}, 1793698200)
        self.assertEqual(len(set_fields.call_args_list), 1)
        self.assertEqual(set_fields.call_args.args[2], {"opsgenie_open": "1", "opsgenie_priority": "P1"})

    def test_priority_reconciliation_reads_remote_before_updating(self):
        with patch.object(digest, "_request", return_value={"data": {"priority": "P1"}}), \
             patch.object(digest, "_ops_action") as action:
            digest._ensure_opsgenie_priority("securityhub-group-test", "P1")
        action.assert_not_called()
        with patch.object(digest, "_request", return_value={"data": {"priority": "P2"}}), \
             patch.object(digest, "_ops_action") as action:
            digest._ensure_opsgenie_priority("securityhub-group-test", "P1")
        self.assertIn("/priority?", action.call_args.args[1])

    def test_closing_missing_alias_is_idempotent(self):
        missing = urllib.error.HTTPError("https://example.test", 404, "missing", {}, None)
        with patch.object(digest, "_request", side_effect=missing), \
             patch.object(digest, "_ops_action") as action:
            digest._close_opsgenie_alias("securityhub-group-test", "cleared")
        action.assert_not_called()

    def test_superseded_group_closes_after_replacement_opens(self):
        groups = {"new-group": [{"previous_group_key": "old-group"}]}
        def get_item(_table, key):
            return {"opsgenie_open": "1"} if key == "group#new-group" else {"urgent_state": "SENT"}
        with patch.object(digest, "_get_item", side_effect=get_item), \
             patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_set_fields") as set_fields:
            self.assertEqual(digest.migrate_previous_groups(object(), groups), 1)
        self.assertEqual(close.call_args.args[0], "securityhub-group-old-group")
        self.assertEqual(set_fields.call_args.args[1], "group#old-group")

    def test_closed_legacy_group_is_skipped_without_another_read(self):
        groups = {"new-group": [{"previous_group_key": "old-group"}]}
        with patch.object(digest, "_get_item", return_value={"opsgenie_open": "1"}) as get_item, \
             patch.object(digest, "_close_opsgenie_alias") as close:
            self.assertEqual(digest.migrate_previous_groups(object(), groups, {"old-group"}), 0)
        self.assertEqual(get_item.call_count, 1)
        close.assert_not_called()

    def test_migration_triggers_one_slack_brief_until_acknowledged(self):
        record = {"previous_group_key": "old-group", "migration_brief_pending": True, "pending": True}
        self.assertTrue(digest._migration_slack_due({"new-group": [record]}))
        record["pending"] = False
        self.assertFalse(digest._migration_slack_due({"new-group": [record]}))
        record["pending"] = True
        record.pop("migration_brief_pending")
        self.assertFalse(digest._migration_slack_due({"new-group": [record]}))

    def test_ledger_scan_identifies_groups_that_may_need_opsgenie_action(self):
        class Table:
            def scan(self, **_kwargs):
                return {"Items": [
                    {"finding_key": {"S": "finding"}, "notification_kind": {"S": "finding"},
                     "notification_payload": {"S": json.dumps({"created_at": "2026-11-03T09:30:00Z"})}},
                    {"finding_key": {"S": "group#open"}, "opsgenie_open": {"S": "1"}},
                    {"finding_key": {"S": "group#urgent"}, "urgent_state": {"S": "SENT"}},
                    {"finding_key": {"S": "group#idle"}, "opsgenie_open": {"S": "0"}},
                    {"finding_key": {"S": "group#old"}, "superseded_group_closed": {"S": "1"}},
                ]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test-table", "FINDING_CUTOVER_AT": "2026-11-03T08:30:00Z"}):
            records, active_markers, closed_markers = digest.scan_findings(Table())
        self.assertEqual(len(records), 1)
        self.assertEqual(active_markers, {"open", "urgent"})
        self.assertEqual(closed_markers, {"old"})
        self.assertFalse(digest._needs_opsgenie_sync({"priority": None}, "idle", active_markers))
        self.assertTrue(digest._needs_opsgenie_sync({"priority": None}, "urgent", active_markers))
        self.assertTrue(digest._needs_opsgenie_sync({"priority": "P1"}, "idle", active_markers))

    def test_digest_skips_state_reads_for_routine_groups(self):
        records = [{"group": {"key": str(index)}} for index in range(100)]
        with patch.object(digest, "_get_item", return_value={}) as get_item, \
             patch.object(digest, "reconcile_findings", return_value=(0, 0, False)), \
             patch.object(digest, "scan_findings", return_value=(records, set(), set())), \
             patch.object(digest, "summarize_group", return_value={"priority": None}), \
             patch.object(digest, "_daily_due", return_value=False), \
             patch.object(digest, "migrate_legacy_alerts", return_value=0), \
             patch.object(digest, "migrate_previous_groups", return_value=0), \
             patch.object(digest, "_set_fields"), \
             patch.object(digest, "sync_opsgenie") as sync:
            digest.run(object(), object(), object(), now=1793698200)
        self.assertEqual(get_item.call_count, 1)
        sync.assert_not_called()

    def test_urgent_only_alert_closes_after_stable_quiet_hour(self):
        summary = {"group": {"key": "group"}, "priority": None,
                   "latest_updated_at": "2026-11-03T09:45:00Z"}
        start = 1793698200
        with patch.object(digest, "_set_fields") as set_fields, \
             patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_clear_urgent_claim") as clear:
            digest.sync_opsgenie(object(), summary, {"urgent_state": "SENT"}, start)
            self.assertEqual(set_fields.call_args.args[2]["opsgenie_no_urgent_since"],
                             digest.datetime.fromtimestamp(start, digest.timezone.utc).isoformat())
            close.assert_not_called()
            state = {"urgent_state": "SENT", "opsgenie_no_urgent_since":
                     digest.datetime.fromtimestamp(start, digest.timezone.utc).isoformat()}
            summary["latest_updated_at"] = "2026-11-03T10:45:00Z"
            digest.sync_opsgenie(object(), summary, state, start + digest.QUIET_CLOSE_SECONDS + 1)
            close.assert_called_once()
            clear.assert_called_once()
            self.assertEqual(set_fields.call_args.args[2]["opsgenie_open"], "0")

    def test_closed_group_does_not_close_again(self):
        summary = {"group": {"key": "group"}, "priority": None,
                   "latest_updated_at": "2026-11-03T09:45:00Z"}
        with patch.object(digest, "_set_fields") as set_fields, \
             patch.object(digest, "_close_opsgenie_alias") as close:
            digest.sync_opsgenie(object(), summary, {"opsgenie_open": "0"}, 1793698200)
        set_fields.assert_not_called()
        close.assert_not_called()

    def test_ec2_cves_on_same_instance_share_group(self):
        resource = {"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-1",
                    "Details": {"AwsEc2Instance": {"ImageId": "ami-1"}}}
        first = router._group_identity(finding("CVE-1", resource))
        second = router._group_identity(finding("CVE-2", resource))
        self.assertEqual(first["key"], second["key"])
        self.assertIn("i-1", first["label"])

    def test_ecr_cves_are_distinct_remediation_groups(self):
        def image(repo, digest):
            return {"Type": "AwsEcrContainerImage", "Id": f"arn:aws:ecr:eu-central-1:123456789012:repository/{repo}",
                    "Details": {"AwsEcrContainerImage": {"RepositoryName": repo, "ImageDigest": digest}}}
        first = router._group_identity(finding("CVE-1", image("api", "sha256:aaa")))
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-2", image("api", "sha256:aaa")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-3", image("api", "sha256:bbb")))["key"])
        self.assertNotEqual(first["key"], router._group_identity(finding("CVE-4", image("web", "sha256:aaa")))["key"])

    def test_ecr_image_id_without_vulnerability_metadata_keeps_findings_distinct(self):
        image_id = "arn:aws:ecr:eu-central-1:123456789012:repository/api/sha256:" + "a" * 64
        resource = {"Type": "AwsEcrContainerImage", "Id": image_id}
        self.assertNotEqual(router._group_identity(finding("CVE-1", resource))["key"],
                            router._group_identity(finding("CVE-2", resource))["key"])

    def test_distinct_critical_cves_each_get_urgent_claim(self):
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
            item = by_key.get(key, {})
            if not item:
                return {}
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
        self.assertEqual(counts, {"recorded": 2, "urgent": 2, "urgent_slack": 2, "skipped": 0})

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
