"""Production regression cases for grouped Security Hub delivery."""

import json
import os
import pathlib
import sys
import unittest
from unittest.mock import patch

from botocore.exceptions import ClientError

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "functions"))
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
import finding_router as router
import finding_policy as policy
import group_digest as digest
import opsgenie_notifier as notifier


def image_finding(identifier="finding-a", severity="CRITICAL"):
    digest = "a" * 64
    return {
        "Id": f"arn:aws:inspector2:us-east-2:123456789012:finding/{'b' * 32}",
        "AwsAccountId": "123456789012",
        "ProductArn": "arn:aws:securityhub:us-east-2::product/aws/inspector",
        "ProductName": "Inspector", "Title": identifier,
        "CreatedAt": "2026-11-04T08:00:00Z", "UpdatedAt": "2026-11-04T08:01:00Z",
        "RecordState": "ACTIVE", "Workflow": {"Status": "NEW"},
        "Severity": {"Label": severity},
        "Resources": [{"Type": "AwsEcrContainerImage", "Id":
                       f"arn:aws:ecr:us-east-2:123456789012:repository/sample-api/sha256:{digest}",
                       "Details": {"AwsEcrContainerImage": {"RepositoryName": "sample-api"}}}],
        "Vulnerabilities": [{"Id": "CVE-2026-10001", "ExploitAvailable": "YES"}],
    }


class HardeningTests(unittest.TestCase):
    def test_same_aws_timestamp_accepts_policy_only_change(self):
        item = image_finding()
        previous = router._compact_finding(item)
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_state": "ACTIVE", "notification_pending": "0"}
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SECURITY_ENVIRONMENT": "Production"}), \
             patch.object(router, "_get_item", return_value=current):
            self.assertTrue(router._record_grouped(table, item, verified={"deployment": "deployed", "exposure": "unknown"}))
        stored = json.loads(table.request["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(stored["risk_context"]["deployment"], "deployed")
        self.assertEqual(stored["page_priority"], "P2")
        self.assertEqual(table.request["ExpressionAttributeValues"][":pending"]["S"], "1")
        self.assertIn("#payload = :observed_payload", table.request["ConditionExpression"])

    def test_same_timestamp_p2_to_p1_policy_change_is_pending_for_delivery(self):
        item = image_finding()
        previous = router._compact_finding(item)
        self.assertEqual(previous["page_priority"], "P2")
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_state": "ACTIVE", "notification_pending": "0"}
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        policy = {"ecr_emergency_vulnerability_ids": ["CVE-2026-10001"]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "PAGING_POLICY": json.dumps(policy)}), \
             patch.object(router, "_get_item", return_value=current):
            self.assertTrue(router._record_grouped(table, item))
        values = table.request["ExpressionAttributeValues"]
        self.assertEqual(json.loads(values[":payload"]["S"])["page_priority"], "P1")
        self.assertEqual(values[":pending"]["S"], "1")

    def test_equal_timestamp_conflicting_aws_snapshot_is_rejected(self):
        item = image_finding(severity="HIGH")
        previous = router._compact_finding(image_finding(severity="CRITICAL"))
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"]))}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), patch.object(router, "_get_item", return_value=current):
            self.assertFalse(router._record_grouped(object(), item))

    def test_router_uses_accepted_ledger_policy_and_rejects_stale_event(self):
        item = image_finding()
        stored = router._compact_finding(item)
        stored["page_priority"] = "P1"
        stored["priority_reason"] = "Verified urgent threat"
        stored["realtime"] = True
        marker = "group#" + stored["page_group"]["key"]
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": [item]}}
        env = {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
               "HIGH_TOPIC_ARN": "high", "SLACK_TOPIC_ARN": "slack", "DELIVERY_TABLE_NAME": "table"}
        def get_item(_table, key):
            if key == marker:
                return {}
            return {"notification_updated_at": item["UpdatedAt"], "notification_state": "ACTIVE",
                    "notification_payload": json.dumps(stored)}
        with patch.dict(os.environ, env), patch.object(router, "_record_grouped", return_value=False), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_inspector_ecr_evidence", return_value={}), \
             patch.object(router, "_publish_once", return_value=True) as publish:
            counts = router.route_event(event, type("Table", (), {"update_item": lambda *a, **k: None})(), object())
        self.assertEqual(counts["urgent"], 1)
        self.assertIn("critical", [call.args[3] for call in publish.call_args_list])

        stale = {**item, "UpdatedAt": "2026-11-04T08:00:00Z"}
        with patch.dict(os.environ, env), patch.object(router, "_record_grouped", return_value=False), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_inspector_ecr_evidence", return_value={}), \
             patch.object(router, "_publish_once") as publish:
            counts = router.route_event({**event, "detail": {"findings": [stale]}}, object(), object())
        self.assertEqual(counts["urgent"], 0)
        publish.assert_not_called()

    def test_positive_inspector_use_is_deployed_but_zero_or_missing_is_unknown(self):
        item = image_finding()
        arn = item["Id"]
        details = {"awsEcrContainerImage": {"imageHash": "sha256:" + "a" * 64,
                                           "repositoryName": "sample-api", "inUseCount": 2}}
        class Inspector:
            def __init__(self, findings):
                self.findings = findings
            def list_findings(self, **kwargs):
                return {"findings": self.findings}
        result = {"findingArn": arn, "awsAccountId": "123456789012", "resources": [
            {"type": "AWS_ECR_CONTAINER_IMAGE", "details": details}]}
        self.assertEqual(router._inspector_ecr_evidence(item, Inspector([result]))["deployment"], "observed_in_use")
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production", "PAGING_POLICY": "{}"}):
            self.assertEqual(policy.paging_priority(item, {"deployment": "observed_in_use", "exposure": "exposed"}), "P2")
        details["awsEcrContainerImage"]["inUseCount"] = 0
        self.assertEqual(router._inspector_ecr_evidence(item, Inspector([result])), {})
        details["awsEcrContainerImage"]["inUseCount"] = 2
        details["awsEcrContainerImage"]["imageHash"] = "sha256:" + "c" * 64
        self.assertEqual(router._inspector_ecr_evidence(item, Inspector([result])), {})

        class DeniedInspector:
            def list_findings(self, **_kwargs):
                raise RuntimeError("access denied")
        with patch.object(router.LOG, "warning") as warning:
            self.assertEqual(router._inspector_ecr_evidence(item, DeniedInspector()), {})
        warning.assert_called_once()

    def test_expired_positive_image_use_reverts_to_unknown(self):
        item = image_finding()
        verified = {"deployment": "deployed", "checked_at": "2026-11-03T00:00:00Z"}
        previous = router._compact_finding(item, verified)
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_state": "ACTIVE", "notification_pending": "0"}
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router.time, "time", return_value=1793900000):
            self.assertTrue(router._record_grouped(table, item))
        stored = json.loads(table.request["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(stored["risk_context"]["deployment"], "unknown")

    def test_paging_incident_transitions_after_quiet_period_with_routine_findings(self):
        routine = router._compact_finding(image_finding(severity="HIGH"))
        self.assertIsNone(routine["page_priority"])
        summary = digest.summarize_group([routine], identity="page_group")
        state = {"opsgenie_open": "1", "opsgenie_priority": "P2",
                 "opsgenie_no_urgent_since": "2026-11-04T08:00:00Z"}
        with patch.dict(os.environ, {"QUIET_PERIOD_SECONDS": "3600"}), \
             patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_set_fields"), patch.object(digest, "_clear_urgent_claim") as clear:
            digest.sync_opsgenie(object(), summary, state, 1793790001)
        close.assert_called_once()
        clear.assert_called_once()

    def test_downgrade_clears_p1_claim_for_future_escalation(self):
        p2 = router._compact_finding(image_finding())
        summary = digest.summarize_group([p2], identity="page_group")
        state = {"opsgenie_open": "1", "opsgenie_priority": "P1",
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": summary["urgent_signature"],
                 "critical_state": "SENT"}
        with patch.object(digest, "_ensure_opsgenie_priority") as priority, \
             patch.object(digest, "_ops_action"), \
             patch.object(digest, "_set_fields"), \
             patch.object(digest, "_clear_critical_claim") as clear:
            digest.sync_opsgenie(object(), summary, state, 1793790001)
        priority.assert_called_once()
        clear.assert_called_once()

    def test_failed_p1_claim_clear_keeps_downgrade_retryable(self):
        record = router._compact_finding(image_finding())
        summary = digest.summarize_group([record], identity="page_group")
        state = {"opsgenie_open": "1", "opsgenie_priority": "P1",
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": summary["urgent_signature"]}
        with patch.object(digest, "_ensure_opsgenie_priority"), \
             patch.object(digest, "_clear_critical_claim", side_effect=RuntimeError("DDB unavailable")), \
             patch.object(digest, "_set_fields") as set_fields:
            with self.assertRaisesRegex(RuntimeError, "DDB unavailable"):
                digest.sync_opsgenie(object(), summary, state, 1793790001)
        set_fields.assert_not_called()

    def test_large_ledger_fails_explicitly_after_paginated_capacity_bound(self):
        """The current worker must report, never silently truncate, 100k+ findings."""
        record = router._compact_finding(image_finding())
        payload = json.dumps(record)
        row = {"finding_key": {"S": record["finding_key"]},
               "notification_kind": {"S": "finding"},
               "notification_payload": {"S": payload}}

        class Table:
            calls = 0
            def scan(self, **request):
                self.calls += 1
                self.assert_request = request
                result = {"Items": [row] * 1000, "ScannedCount": 1000,
                          "ConsumedCapacity": {"CapacityUnits": 125.0}}
                if self.calls < 101:
                    result["LastEvaluatedKey"] = {"finding_key": {"S": str(self.calls)}}
                return result

        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test",
                                  "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            with self.assertRaisesRegex(RuntimeError, "exceeded 100000 items"):
                digest.scan_findings(table)
        self.assertEqual(table.calls, 101)
        self.assertEqual(table.assert_request["ReturnConsumedCapacity"], "TOTAL")

    def test_guardduty_probe_is_slack_only_and_urgent_threat_pages_once(self):
        probe = image_finding("probe", severity="HIGH")
        probe.update({"Id": "guardduty-probe", "ProductName": "GuardDuty",
                      "Types": ["TTPs/Discovery/Recon:EC2-PortProbeUnprotectedPort"],
                      "Action": {"PortProbeAction": {"PortProbeDetails": [{}]}},
                      "Resources": [{"Type": "AwsEc2Instance", "Id": "i-example-1"}]})
        threat = {**probe, "Id": "guardduty-threat",
                  "Types": ["TTPs/Initial Access/UnauthorizedAccess:EC2-SSHBruteForce"], "Action": {}}
        published = set()
        def get_item(_table, key):
            for finding in (probe, threat):
                if key == router._finding_key(finding):
                    return {"notification_updated_at": finding["UpdatedAt"], "notification_state": "ACTIVE",
                            "notification_payload": json.dumps(router._compact_finding(finding))}
            return {}
        def publish(_table, _sns, marker, destination, *_args):
            identity = (marker, destination)
            if identity in published:
                return False
            published.add(identity)
            return True
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": [probe]}}
        env = {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
               "HIGH_TOPIC_ARN": "high", "SLACK_TOPIC_ARN": "slack", "DELIVERY_TABLE_NAME": "table",
               "PAGING_POLICY": json.dumps({"guardduty_types": ["UnauthorizedAccess:"]})}
        table = type("Table", (), {"update_item": lambda *a, **k: None})()
        with patch.dict(os.environ, env), patch.object(router, "_record_grouped", return_value=True), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_publish_once", side_effect=publish):
            first = router.route_event(event, table, object())
            repeated = router.route_event(event, table, object())
            urgent = router.route_event({**event, "detail": {"findings": [threat]}}, table, object())
        self.assertEqual((first["urgent"], first["urgent_slack"]), (0, 1))
        self.assertEqual((repeated["urgent"], repeated["urgent_slack"]), (0, 0))
        self.assertEqual((urgent["urgent"], urgent["urgent_slack"]), (1, 1))

    def test_p2_to_p1_uses_existing_alias_without_new_alert(self):
        finding = image_finding()
        group = router._compact_finding(finding)["page_group"]
        calls = []
        def request(method, path, payload=None):
            calls.append((method, path, payload))
            return {"data": {"status": "open", "priority": "P2"}} if method == "GET" else {"requestId": "ok"}
        with patch.object(notifier, "_request", side_effect=request), \
             patch.object(notifier, "_wait_for_request") as wait:
            notifier.deliver({"detail": {"findings": [finding]}, "_dasmeta_group_urgent": True,
                              "_dasmeta_group": group, "_dasmeta_page_priority": "P1"})
        self.assertEqual([method for method, _, _ in calls], ["GET", "PUT"])
        self.assertIn("/priority?", calls[-1][1])
        wait.assert_called_once_with("ok")

    def test_p1_vulnerability_addition_and_partial_resolution_update_without_recreate(self):
        first = router._compact_finding(image_finding("first"))
        second_finding = image_finding("second")
        second_finding["Id"] = second_finding["Id"].replace("b" * 32, "c" * 32)
        second_finding["Vulnerabilities"][0]["Id"] = "CVE-2026-10002"
        second = router._compact_finding(second_finding)
        first["page_priority"] = second["page_priority"] = "P1"
        summary = digest.summarize_group([first, second], identity="page_group")
        self.assertEqual(summary["priority"], "P1")
        self.assertEqual(len(summary["vulnerability_ids"]), 2)
        state = {"opsgenie_open": "1", "opsgenie_priority": "P1",
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": "old"}
        with patch.object(digest, "_ops_action") as action, patch.object(digest, "_set_fields"):
            digest.sync_opsgenie(object(), summary, state, 1793790000)
        self.assertFalse(any(call.args[1] == "/v2/alerts" for call in action.call_args_list))
        self.assertTrue(any("/description?" in call.args[1] for call in action.call_args_list))
        first["record_state"] = "ARCHIVED"
        remaining = digest.summarize_group([first, second], identity="page_group")
        self.assertEqual(remaining["priority"], "P1")
        with patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_ops_action") as action, patch.object(digest, "_set_fields"):
            digest.sync_opsgenie(object(), remaining, state, 1793790001)
        close.assert_not_called()
        self.assertTrue(any("/description?" in call.args[1] for call in action.call_args_list))

    def test_legacy_alias_migration_requires_replacement_and_is_retryable(self):
        record = router._compact_finding(image_finding())
        record["legacy_opsgenie"] = True
        record["pending"] = True
        summary = digest.summarize_group([record], identity="page_group")
        marker = "group#" + summary["group"]["key"]
        with patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_close_opsgenie_alias") as close:
            self.assertEqual(digest.migrate_legacy_alerts(object(), [record], summary), 0)
        close.assert_not_called()
        with patch.object(digest, "_get_item", return_value={"opsgenie_open": "1"}), \
             patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_set_fields") as set_fields:
            self.assertEqual(digest.migrate_legacy_alerts(object(), [record], summary), 1)
        close.assert_called_once()
        self.assertEqual(set_fields.call_args.args[1], record["finding_key"])
        self.assertEqual(marker, "group#" + record["page_group"]["key"])

    def test_already_closed_legacy_alias_needs_no_second_close(self):
        with patch.object(digest, "_request", return_value={"data": {"status": "closed"}}), \
             patch.object(digest, "_ops_action") as action:
            digest._close_opsgenie_alias("securityhub-example", "migrated")
        action.assert_not_called()

    def test_daily_ack_does_not_clear_same_timestamp_policy_change(self):
        record = router._compact_finding(image_finding())
        record["_ledger_payload"] = json.dumps(record)
        newer = {**record, "page_priority": "P1"}
        current_payload = json.dumps(newer)
        class Table:
            pending = "1"
            def update_item(self, **request):
                self.request = request
                expected = request["ExpressionAttributeValues"][":payload"]["S"]
                if current_payload != expected:
                    raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
                self.pending = "0"
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            digest._acknowledge_new(table, [record])
        self.assertEqual(table.pending, "1")
        self.assertIn("#payload = :payload", table.request["ConditionExpression"])

    def test_daily_application_summary_shows_observed_image_use(self):
        record = router._compact_finding(image_finding(), {"deployment": "observed_in_use"})
        record["pending"] = False
        payloads = []
        with patch.dict(os.environ, {"DAILY_DIGEST_MAX_GROUPS": "5"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), {record["group"]["key"]: [record]}, 1793790000)
        self.assertEqual(payloads[0]["application_summaries"][0]["deployment_status"], "observed in use")


if __name__ == "__main__":
    unittest.main()
