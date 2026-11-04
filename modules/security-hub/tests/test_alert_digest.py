"""Behavioral tests for grouped alert policy and the daily security brief."""

import importlib.util
import json
import os
import pathlib
import sys
import time
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "functions"))
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
import finding_policy as policy
import finding_router as router
import group_digest as digest
import opsgenie_notifier as notifier

SLACK = ROOT.parent / "cloudwatch-alarm-actions" / "functions" / "notify_slack.py"
spec = importlib.util.spec_from_file_location("security_notify_slack", SLACK)
slack = importlib.util.module_from_spec(spec)
spec.loader.exec_module(slack)


def finding(identifier="finding-1", severity="HIGH", product="Inspector", exploit=False):
    return {
        "Id": identifier, "AwsAccountId": "123456789012",
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "ProductName": product, "Title": "Review vulnerable package",
        "CreatedAt": "2026-11-04T08:00:00Z", "UpdatedAt": "2026-11-04T08:01:00Z",
        "RecordState": "ACTIVE", "Workflow": {"Status": "NEW"},
        "Severity": {"Label": severity},
        "Resources": [{"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-123"}],
        "Vulnerabilities": [{"Id": "CVE-1", "ExploitAvailable": "YES" if exploit else "NO"}],
    }


def ecr_finding(identifier, digest, vulnerability="CVE-2026-10001", package="pillow", repository="sample-api"):
    item = finding(identifier=identifier, exploit=True)
    item["Title"] = f"{vulnerability} - {package}"
    item["Resources"] = [{
        "Type": "AwsEcrContainerImage",
        "Id": f"arn:aws:ecr:eu-central-1:123456789012:repository/{repository}/sha256:{digest}",
        "Details": {"AwsEcrContainerImage": {"RepositoryName": repository, "ImageDigest": f"sha256:{digest}"}},
    }]
    item["Vulnerabilities"] = [{"Id": vulnerability, "ExploitAvailable": "YES",
                                "VulnerablePackages": [{"Name": package}]}]
    return item


def record(identifier, group, severity="HIGH", pending=False, state="ACTIVE"):
    return {
        "finding_key": identifier, "finding_id": identifier, "account": "123456789012",
        "group": group, "record_state": state, "workflow": "NEW" if state == "ACTIVE" else "RESOLVED",
        "severity": severity, "exploit_available": "NO", "page_priority": None,
        "compliance_status": "", "resource": "arn:aws:ec2:eu-central-1:123456789012:instance/" + identifier,
        "resource_ids": ["arn:aws:ec2:eu-central-1:123456789012:instance/" + identifier],
        "title": "Review affected workload", "vulnerability_ids": ["CVE-1"],
        "created_at": "2026-11-04T08:00:00Z", "updated_at": "2026-11-04T08:01:00Z",
        "pending": pending, "change_kind": "new",
    }


def group(key, product="Inspector"):
    return {"key": key, "label": f"{product} | workload-{key}", "account": "123456789012",
            "region": "eu-central-1", "product": product, "cluster": "", "nodepool": "", "image": "",
            "environment": "Production"}


class AlertDigestTests(unittest.TestCase):
    def test_ecr_same_cve_package_across_digests_is_one_group(self):
        first = ecr_finding("f-1", "a" * 64)
        second = ecr_finding("f-2", "b" * 64)
        a, b = router._compact_finding(first), router._compact_finding(second)
        self.assertEqual(a["group"]["key"], b["group"]["key"])
        self.assertNotEqual(a["resource"], b["resource"])
        summary = digest.summarize_group([a, b])
        self.assertEqual(summary["affected_images"], 2)
        self.assertEqual(len(summary["vulnerability_ids"]), 1)
        self.assertEqual(summary["group"]["deployment_status"], "unknown")

    def test_ecr_group_distinguishes_package_repository_region_and_environment(self):
        base = ecr_finding("f-1", "a" * 64)
        changed = []
        package = ecr_finding("f-2", "b" * 64, package="glibc")
        changed.append(package)
        changed.append(ecr_finding("f-3", "b" * 64, repository="sample-worker"))
        changed.append(ecr_finding("f-4", "b" * 64, vulnerability="CVE-2026-10002"))
        region = ecr_finding("f-5", "b" * 64)
        region["Resources"][0]["Id"] = region["Resources"][0]["Id"].replace("eu-central-1", "us-east-1")
        changed.append(region)
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production"}):
            key = router._group_identity(base)["key"]
            self.assertTrue(all(router._group_identity(item)["key"] != key for item in changed))
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Development"}):
            self.assertNotEqual(router._group_identity(base)["key"], key)

    def test_routine_high_ecr_is_digest_only_without_verified_exposure(self):
        item = ecr_finding("f-1", "a" * 64)
        with patch.dict(os.environ, {"REALTIME_ENABLED": "true", "HIGH_REQUIRES_EXPLOIT": "true",
                                  "HIGH_REQUIRES_PUBLIC_EXPOSURE": "true", "PAGING_POLICY": json.dumps({"high_exploitable": True, "require_public_exposure": True})}):
            self.assertFalse(policy.realtime(item))
            self.assertIsNone(policy.paging_priority(item))

    def test_daily_digest_consolidates_application_images_and_hides_digests(self):
        first = router._compact_finding(ecr_finding("f-1", "a" * 64))
        second = router._compact_finding(ecr_finding("f-2", "b" * 64))
        for item in (first, second):
            item["pending"] = True
        groups = {first["group"]["key"]: [first, second]}
        payloads = []
        with patch.dict(os.environ, {"DAILY_DIGEST_MAX_GROUPS": "5"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), groups, 1793782800)
        self.assertEqual(payloads[0]["active_count"], 2)
        self.assertEqual(payloads[0]["application_summaries"][0]["images"], 2)
        self.assertEqual(payloads[0]["application_summaries"][0]["vulnerabilities"], 1)
        formatted = slack.format_group_digest({"_dasmeta_group_digest": digest._slack_payload(payloads[0], False)["_dasmeta_group_digest"]})
        self.assertIn("sample-api", formatted["text"])
        self.assertIn("1 vulnerability across 2 images", formatted["text"])
        self.assertIn("deployment unknown", formatted["text"])
        self.assertNotIn("*Priority findings*", formatted["text"])
        self.assertNotIn("sha256:", formatted["text"])

    def test_lifecycle_escalation_resolution_and_reopen_keep_one_finding_key(self):
        original = finding(severity="HIGH")
        previous = router._compact_finding(original)
        previous["change_kind"] = "new"

        class Table:
            update = None

            def update_item(self, **kwargs):
                self.update = kwargs

        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_RETENTION_DAYS": "30"}):
            escalated = finding(severity="CRITICAL")
            escalated["UpdatedAt"] = "2026-11-04T08:02:00Z"
            with patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(previous),
                                                                  "notification_updated_at": previous["updated_at"],
                                                                  "notification_pending": "0", "notification_state": "ACTIVE"}):
                self.assertTrue(router._record_grouped(table, escalated))
            changed = json.loads(table.update["ExpressionAttributeValues"][":payload"]["S"])
            self.assertEqual(changed["change_kind"], "escalated")
            self.assertEqual(table.update["ExpressionAttributeValues"][":pending"]["S"], "1")
            self.assertEqual(changed["finding_key"], previous["finding_key"])

            resolved = finding(severity="HIGH")
            resolved["UpdatedAt"] = "2026-11-04T08:03:00Z"
            resolved["RecordState"] = "ARCHIVED"
            with patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(previous),
                                                                  "notification_updated_at": previous["updated_at"],
                                                                  "notification_pending": "0", "notification_state": "ACTIVE"}):
                self.assertTrue(router._record_grouped(table, resolved))
            closed = json.loads(table.update["ExpressionAttributeValues"][":payload"]["S"])
            self.assertEqual(closed["change_kind"], "resolved")
            self.assertIn(":expiry", table.update["ExpressionAttributeValues"])

            reopened = finding(severity="HIGH")
            reopened["UpdatedAt"] = "2026-11-04T08:04:00Z"
            with patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(closed),
                                                                  "notification_updated_at": closed["updated_at"],
                                                                  "notification_pending": "0", "notification_state": "ARCHIVED"}):
                self.assertTrue(router._record_grouped(table, reopened))
            again = json.loads(table.update["ExpressionAttributeValues"][":payload"]["S"])
            self.assertEqual(again["change_kind"], "reopened")
            self.assertIn("REMOVE #expiry", table.update["UpdateExpression"])

    def test_duplicate_and_out_of_order_events_do_not_overwrite_current_snapshot(self):
        item = finding()
        compact = router._compact_finding(item)
        class Table:
            def update_item(self, **_kwargs):
                raise AssertionError("out-of-order event must not write")
        with patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(compact),
                                                              "notification_updated_at": compact["updated_at"]}):
            self.assertFalse(router._record_grouped(Table(), item))
            older = finding()
            older["UpdatedAt"] = "2026-11-04T07:59:00Z"
            self.assertFalse(router._record_grouped(Table(), older))
        fractional = dict(compact, updated_at="2026-11-04T08:01:00.001Z")
        with patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(fractional),
                                                              "notification_updated_at": fractional["updated_at"]}):
            # Lexical comparison would incorrectly treat the whole-second Z as newer.
            self.assertFalse(router._record_grouped(Table(), item))

    def test_new_critical_in_open_group_has_its_own_immediate_claim(self):
        item = finding(severity="CRITICAL")
        current = router._compact_finding(item)
        group_key = "group#" + current["group"]["key"]
        published = []

        class Table:
            def update_item(self, **_kwargs):
                pass

        def get_item(_table, key):
            if key == group_key:
                return {"urgent_state": "SENT", "urgent_slack_state": "SENT"}
            return {"notification_updated_at": item["UpdatedAt"], "notification_state": "ACTIVE",
                    "notification_payload": json.dumps(current)}

        def publish(_table, _sns, marker, destination, *_args):
            published.append((marker, destination))
            return True

        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": [item]}}
        with patch.dict(os.environ, {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
                                      "HIGH_TOPIC_ARN": "high", "SLACK_TOPIC_ARN": "slack", "PAGING_POLICY": "{}",
                                      "DELIVERY_TABLE_NAME": "test"}), \
             patch.object(router, "_record_grouped", return_value=True), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_publish_once", side_effect=publish):
            router.route_event(event, Table(), object(), now=1793779260)
        self.assertEqual(len(published), 2)
        self.assertTrue(all(marker == group_key for marker, _ in published))
        self.assertEqual({destination for _, destination in published}, {"critical", "critical_slack"})

    def test_new_cves_in_alerted_image_reuse_group_claim(self):
        first = finding("cve-a", severity="HIGH", exploit=True)
        second = finding("cve-b", severity="HIGH", exploit=True)
        group_key = "group#" + router._group_identity(first)["key"]
        calls = []

        def get_item(_table, key):
            if key == group_key:
                return {"urgent_state": "SENT", "urgent_slack_state": "SENT"}
            current = first if key == router._finding_key(first) else second
            return {"notification_updated_at": current["UpdatedAt"], "notification_state": "ACTIVE",
                    "notification_payload": json.dumps(router._compact_finding(current))}

        def publish(_table, _sns, marker, destination, *_args):
            calls.append((marker, destination))
            return False

        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": [first, second]}}
        with patch.dict(os.environ, {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
                                      "HIGH_TOPIC_ARN": "high", "SLACK_TOPIC_ARN": "slack", "PAGING_POLICY": "{}"}), \
             patch.object(router, "_record_grouped", return_value=True), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_publish_once", side_effect=publish):
            router.route_event(event, object(), object(), now=1793779260)
        self.assertEqual(calls, [])  # Exploit availability without verified exposure is routine HIGH.

    def test_page_policy_requires_real_context_for_high_and_guardduty(self):
        high = finding()
        with patch.dict(os.environ, {"PAGING_POLICY": json.dumps({"guardduty_types": ["Recon:"]}),
                                      "GUARD_DUTY_MIN_SEVERITY": "HIGH", "SECURITY_ENVIRONMENT": "Production"}):
            self.assertIsNone(policy.paging_priority(high))
            self.assertEqual(policy.paging_priority(finding(severity="CRITICAL")), "P1")
            self.assertIsNone(policy.paging_priority(finding(exploit=True)))
            exposed = finding(exploit=True)
            exposed["Resources"][0]["Details"] = {"AwsEc2Instance": {"PublicIpAddress": "192.0.2.1"}}
            self.assertEqual(policy.paging_priority(exposed), "P1")
            threat = finding(product="GuardDuty")
            threat["Types"] = ["Recon:EC2/PortProbeUnprotectedPort"]
            self.assertEqual(policy.paging_priority(threat), "P1")
            threat["Types"] = ["Policy:IAMUser/RootCredentialUsage"]
            self.assertIsNone(policy.paging_priority(threat))
            threat["Vulnerabilities"] = [{"Id": "CVE-1", "ExploitAvailable": "YES"}]
            self.assertIsNone(policy.paging_priority(threat))
        with patch.dict(os.environ, {"PAGING_POLICY": json.dumps({"environments": ["Production"]}),
                                      "SECURITY_ENVIRONMENT": "Development"}):
            self.assertIsNone(policy.paging_priority(finding(exploit=True)))
            self.assertEqual(policy.paging_priority(finding(severity="CRITICAL")), "P1")

    def test_guardduty_group_distinguishes_source_and_type(self):
        first = finding("a", product="GuardDuty")
        second = finding("b", product="GuardDuty")
        for item in (first, second):
            item["Types"] = ["Recon:EC2/PortProbeUnprotectedPort"]
            item["Action"] = {"PortProbeAction": {"PortProbeDetails": [{
                "RemoteIpDetails": {"IpAddressV4": "203.0.113.10"}, "LocalPortDetails": {"Port": 22}}]}}
        self.assertEqual(router._group_identity(first)["key"], router._group_identity(second)["key"])
        second["Action"]["PortProbeAction"]["PortProbeDetails"][0]["RemoteIpDetails"]["IpAddressV4"] = "203.0.113.11"
        self.assertNotEqual(router._group_identity(first)["key"], router._group_identity(second)["key"])
        first["ProductName"] = "Amazon GuardDuty"
        self.assertEqual(router._group_identity(first)["finding_type"], "Recon:EC2/PortProbeUnprotectedPort")

    def test_multi_resource_count_is_distinct(self):
        item = finding()
        item["Resources"].append({"Type": "AwsEc2Instance", "Id": "arn:aws:ec2:eu-central-1:123456789012:instance/i-456"})
        compact = router._compact_finding(item)
        compact["pending"] = True
        self.assertEqual(digest.summarize_group([compact])["affected_resources"], 2)

    def test_daily_sends_still_active_group_with_zero_changes(self):
        groups = {"one": [record("one", group("one"))]}
        payloads = []
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production", "DAILY_DIGEST_MAX_GROUPS": "5"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new") as acknowledge, patch.object(digest, "_set_fields"):
            self.assertTrue(digest.send_slack_batch(object(), object(), groups, 1793782800))
        self.assertEqual(payloads[0]["new_count"], 0)
        self.assertEqual(payloads[0]["active_count"], 1)
        self.assertEqual(payloads[0]["groups_changed_total"], 1)
        acknowledge.assert_called_once()

    def test_risk_order_and_display_limit_ignore_high_volume_low_findings(self):
        groups = {}
        for index in range(8):
            key = str(index)
            severity = "CRITICAL" if index == 7 else "LOW"
            count = 1 if index == 7 else 100
            groups[key] = [record(f"{key}-{n}", group(key), severity, pending=True) for n in range(count)]
        payloads = []
        with patch.dict(os.environ, {"DAILY_DIGEST_MAX_GROUPS": "5"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), groups, 1793782800)
        summary = payloads[0]
        self.assertEqual(summary["top_groups"][0]["severity"], "CRITICAL")
        self.assertEqual(len(summary["top_groups"]), 5)
        self.assertEqual(summary["groups_changed_total"], 8)
        self.assertEqual(summary["new_count"], 701)

    def test_quiet_is_not_misreported_as_resolved(self):
        old = record("one", group("one"), state="ACTIVE")
        old["workflow"] = "SUPPRESSED"
        old["updated_at"] = "2026-11-04T08:00:00Z"
        payloads = []
        with patch.object(digest, "_get_item", return_value={"slack_open": "1"}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"), \
             patch.object(digest, "_clear_urgent_claim"):
            digest.send_slack_batch(object(), object(), {"one": [old]}, 1793782800)
        self.assertEqual(payloads[0]["quiet_count"], 1)
        self.assertEqual(payloads[0]["resolved_count"], 0)

    def test_quiet_group_rearms_all_immediate_alert_tiers(self):
        class Table:
            update = None
            def update_item(self, **kwargs):
                self.update = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            digest._clear_urgent_claim(table, "group#one")
        names = table.update["ExpressionAttributeNames"]
        self.assertIn("critical_state", names.values())
        self.assertIn("critical_slack_state", names.values())
        self.assertIn("escalation_slack_state", names.values())

    def test_utc_daily_gate_and_empty_period(self):
        before = int(datetime(2026, 11, 4, 7, 59, tzinfo=timezone.utc).timestamp())
        after = int(datetime(2026, 11, 4, 8, 1, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DAILY_DIGEST_HOUR_UTC": "8", "DAILY_DIGEST_ENABLED": "true"}):
            self.assertFalse(digest._daily_due({}, before))
            self.assertTrue(digest._daily_due({}, after))
            self.assertFalse(digest._daily_due({"last_daily_slack_at": "2026-11-04T08:00:00Z"}, after))
        payloads = []
        with patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), {}, after)
        self.assertEqual(payloads[0]["active_count"], 0)

    def test_empty_event_is_safe_and_malformed_finding_retries(self):
        base = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported"}
        with patch.dict(os.environ, {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            self.assertEqual(router.route_event({**base, "detail": {"findings": []}}, object(), object())["recorded"], 0)
            with self.assertRaisesRegex(ValueError, "missing CreatedAt"):
                router.route_event({**base, "detail": {"findings": [{"Id": "malformed"}]}}, object(), object())

    def test_missing_vulnerability_metadata_keeps_region_link(self):
        item = finding()
        item.pop("Vulnerabilities")
        compact = router._compact_finding(item)
        self.assertEqual(compact["vulnerability_ids"], [])
        self.assertIn("region=eu-central-1", digest._securityhub_url(compact["group"]))

    def test_slack_messages_are_short_and_do_not_list_finding_ids(self):
        group_data = group("one", "GuardDuty")
        group_data.update({"finding_type": "Recon:EC2/PortProbeUnprotectedPort", "source_ip": "203.0.113.10", "target_port": 22})
        item = finding(product="GuardDuty")
        item["Title"] = "EC2 port probing detected"
        immediate = slack.format_group_urgent({"_dasmeta_group": group_data, "detail": {"findings": [item]}})
        self.assertIn("Source IP", immediate["text"])
        self.assertIn("203.0.113.10", immediate["text"])
        self.assertNotIn(item["Id"], immediate["text"])
        digest_payload = {"_dasmeta_group_digest": {
            "digest_kind": "daily", "new_count": 1, "active_count": 7,
            "new_severities": {"CRITICAL": 1}, "active_severities": {"CRITICAL": 1},
            "affected_resources": 3, "vulnerability_count": 2, "quiet_count": 1, "resolved_count": 0,
            "top_groups": [{"label": group_data["label"], "severity": "CRITICAL", "new": 1,
                            "active": 7, "resources": 3, "action": "Review exposed ports"}],
            "groups_changed_total": 1, "finding_url": "https://console.aws.amazon.com/securityhub/home?region=eu-central-1#/findings",
            "environment": "Production", "account_label": "Production account", "regions": ["eu-central-1"],
            "label": "Security Hub daily digest", "closing": False,
        }}
        formatted = slack.format_group_digest(digest_payload)
        self.assertLessEqual(len(formatted["text"].splitlines()), 20)
        self.assertIn("7 still active", formatted["text"])
        self.assertNotIn(item["Id"], formatted["text"])

    def test_slack_shortens_container_digest(self):
        image = "sha256:" + "a" * 64
        item = finding(product="Inspector")
        item["Resources"] = [{"Type": "AwsEcrContainerImage", "Id": "arn:aws:ecr:eu-central-1:123456789012:repository/app/" + image}]
        rendered = slack.format_group_urgent({"_dasmeta_group": router._group_identity(item), "detail": {"findings": [item]}})
        self.assertIn(image[:19], rendered["text"])
        self.assertNotIn(image, rendered["text"])

    def test_existing_group_receives_new_critical_note(self):
        item = finding(severity="CRITICAL")
        calls = []
        def request(method, path, payload=None):
            calls.append((method, path, payload))
            return {"data": {"priority": "P1"}} if method == "GET" else {"requestId": "ok"}
        with patch.object(notifier, "_request", side_effect=request), patch.object(notifier, "_wait_for_request"):
            notifier.deliver({"detail": {"findings": [item]}, "_dasmeta_group_urgent": True,
                              "_dasmeta_group": group("one"), "_dasmeta_page_priority": "P1"})
        self.assertTrue(any(path.endswith("/notes?identifierType=alias") for method, path, _ in calls if method == "POST"))
        self.assertFalse(any(path == "/v2/alerts" for _, path, _ in calls))

    def test_existing_group_is_promoted_and_annotated(self):
        calls = []
        def request(method, path, payload=None):
            calls.append((method, path))
            return {"data": {"priority": "P2"}} if method == "GET" else {"requestId": "ok"}
        with patch.object(notifier, "_request", side_effect=request), patch.object(notifier, "_wait_for_request"):
            notifier.deliver({"detail": {"findings": [finding(severity="CRITICAL")]},
                              "_dasmeta_group_urgent": True, "_dasmeta_group": group("one"),
                              "_dasmeta_page_priority": "P1"})
        self.assertEqual([method for method, _ in calls], ["GET", "PUT", "POST"])


if __name__ == "__main__":
    unittest.main()
