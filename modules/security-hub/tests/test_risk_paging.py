"""Risk-aware paging and incident identity regression tests."""

import json
import os
import pathlib
import sys
import unittest
import urllib.error
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "functions"))
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
import finding_policy as policy
import finding_router as router
import group_digest as digest
import opsgenie_notifier as notifier


def image_finding(identifier, digest="a" * 64, account="123456789012", severity="CRITICAL", vulnerability=None):
    vulnerability = vulnerability or identifier
    return {
        "Id": identifier, "AwsAccountId": account,
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "ProductName": "Inspector", "Title": f"{vulnerability} - libsample",
        "CreatedAt": "2026-11-04T08:00:00Z", "UpdatedAt": "2026-11-04T08:01:00Z",
        "RecordState": "ACTIVE", "Workflow": {"Status": "NEW"},
        "Severity": {"Label": severity},
        "Resources": [{"Type": "AwsEcrContainerImage",
                       "Id": f"arn:aws:ecr:eu-central-1:{account}:repository/sample-api/sha256:{digest}",
                       "Details": {"AwsEcrContainerImage": {"RepositoryName": "sample-api", "ImageDigest": f"sha256:{digest}"}}}],
        "Vulnerabilities": [{"Id": vulnerability, "ExploitAvailable": "YES",
                             "VulnerablePackages": [{"Name": "libsample"}]}],
    }


class RiskPagingTests(unittest.TestCase):
    def test_distinct_critical_cves_share_one_application_incident(self):
        first = image_finding("CVE-2026-10001")
        second = image_finding("CVE-2026-10002")
        a, b = router._compact_finding(first), router._compact_finding(second)
        self.assertNotEqual(a["group"]["key"], b["group"]["key"])
        self.assertEqual(a["page_group"]["key"], b["page_group"]["key"])
        self.assertEqual((a["page_priority"], b["page_priority"]), ("P2", "P2"))
        summary = digest.summarize_group([a, b], identity="page_group")
        self.assertEqual(summary["priority"], "P2")
        self.assertEqual(len(summary["vulnerability_ids"]), 2)
        self.assertEqual(summary["affected_images"], 1)
        description = digest._opsgenie_description(summary)
        self.assertIn("CVE-2026-10001", description)
        self.assertIn("CVE-2026-10002", description)
        self.assertIn("Deployment: unknown | Exposure: unknown", description)
        self.assertNotIn("sha256:", digest._opsgenie_message(summary))

    def test_same_cve_on_two_digests_is_one_remediation_and_page_group(self):
        a = router._compact_finding(image_finding("finding-a", "a" * 64, vulnerability="CVE-2026-10001"))
        b = router._compact_finding(image_finding("finding-b", "b" * 64, vulnerability="CVE-2026-10001"))
        self.assertEqual(a["group"]["key"], b["group"]["key"])
        self.assertEqual(a["page_group"]["key"], b["page_group"]["key"])
        self.assertEqual(digest.summarize_group([a, b], identity="page_group")["affected_images"], 2)

    def test_one_finding_with_two_repositories_does_not_merge_into_either_application(self):
        item = image_finding("CVE-2026-10001")
        second = image_finding("CVE-2026-10001", digest="b" * 64)["Resources"][0]
        second["Id"] = second["Id"].replace("repository/sample-api/", "repository/sample-worker/")
        second["Details"]["AwsEcrContainerImage"]["RepositoryName"] = "sample-worker"
        item["Resources"].append(second)
        multi = router._compact_finding(item)
        single = router._compact_finding(image_finding("CVE-2026-10001"))
        self.assertNotEqual(multi["page_group"]["key"], single["page_group"]["key"])
        self.assertEqual(multi["group"]["repository"], "")
        self.assertEqual(len(multi["resource_ids"]), 2)

    def test_identical_repository_and_cve_do_not_merge_accounts_or_projects(self):
        first = image_finding("finding-a")
        second = image_finding("finding-a", account="210987654321")
        with patch.dict(os.environ, {"SECURITY_PROJECT": "Project A", "SECURITY_ENVIRONMENT": "Production"}):
            a = router._compact_finding(first)["page_group"]["key"]
            b = router._compact_finding(second)["page_group"]["key"]
        self.assertNotEqual(a, b)
        with patch.dict(os.environ, {"SECURITY_PROJECT": "Project B", "SECURITY_ENVIRONMENT": "Production"}):
            self.assertNotEqual(a, router._compact_finding(first)["page_group"]["key"])
        other_region = image_finding("finding-a")
        other_region["Resources"][0]["Id"] = other_region["Resources"][0]["Id"].replace("eu-central-1", "us-east-2")
        with patch.dict(os.environ, {"SECURITY_PROJECT": "Project A", "SECURITY_ENVIRONMENT": "Production"}):
            self.assertNotEqual(a, router._compact_finding(other_region)["page_group"]["key"])

    def test_unused_image_is_digest_only_when_inventory_is_verified(self):
        item = image_finding("CVE-2026-10001")
        verified = {"deployment": "unused", "exposure": "unexposed"}
        self.assertIsNone(policy.paging_priority(item, verified))
        self.assertFalse(policy.realtime(item, verified))
        with patch.dict(os.environ, {"PAGING_POLICY": json.dumps({"ecr_emergency_vulnerability_ids": ["CVE-2026-10001"]})}):
            self.assertIsNone(policy.paging_priority(item, verified))

    def test_unknown_image_is_p2_and_emergency_override_can_raise_p1(self):
        item = image_finding("CVE-2026-10001")
        with patch.dict(os.environ, {"PAGING_POLICY": "{}", "SECURITY_ENVIRONMENT": "Production"}):
            self.assertEqual(policy.paging_priority(item), "P2")
            self.assertEqual(policy.risk_context(item)["deployment"], "unknown")
            self.assertEqual(policy.risk_context(item)["exposure"], "unknown")
        with patch.dict(os.environ, {"PAGING_POLICY": json.dumps({"ecr_emergency_vulnerability_ids": ["CVE-2026-10001"]}),
                                  "SECURITY_ENVIRONMENT": "Production"}):
            self.assertEqual(policy.paging_priority(item), "P1")

    def test_verified_exploitation_of_deployed_exposed_production_image_is_p1(self):
        item = image_finding("CVE-2026-10001")
        item["Vulnerabilities"][0]["ExploitAvailable"] = "NO"
        verified = {"deployment": "deployed", "exposure": "exposed", "active_exploitation": True}
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production", "PAGING_POLICY": "{}"}):
            self.assertEqual(policy.paging_priority(item, verified), "P1")
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Development", "PAGING_POLICY": "{}"}):
            self.assertEqual(policy.paging_priority(item, verified), "P2")

    def test_high_without_verified_exposure_stays_in_digest(self):
        item = image_finding("CVE-2026-10001", severity="HIGH")
        self.assertIsNone(policy.paging_priority(item))
        self.assertFalse(policy.realtime(item))

    def test_guardduty_port_probe_is_p2_but_confirmed_threat_type_is_p1(self):
        item = image_finding("threat")
        item.update({"ProductName": "GuardDuty", "Types": ["Recon:EC2/PortProbeUnprotectedPort"],
                     "Action": {"PortProbeAction": {"PortProbeDetails": [{}]}}, "Severity": {"Label": "HIGH"}})
        with patch.dict(os.environ, {"PAGING_POLICY": json.dumps({"guardduty_types": ["Recon:", "UnauthorizedAccess:"]})}):
            self.assertEqual(policy.paging_priority(item), "P2")
            item["Types"] = ["UnauthorizedAccess:EC2/SSHBruteForce"]
            item["Action"] = {}
            self.assertEqual(policy.paging_priority(item), "P1")

    def test_p2_then_explicit_p1_uses_same_marker_and_only_one_claim_per_tier(self):
        first = image_finding("CVE-2026-10001")
        second = image_finding("CVE-2026-10002")
        events = [first, second]
        calls = set()
        def get_item(_table, key):
            for item in events:
                if key == router._finding_key(item):
                    return {"notification_updated_at": item["UpdatedAt"], "notification_state": "ACTIVE",
                            "notification_payload": json.dumps(router._compact_finding(item))}
            return {}
        def publish_once(_table, _sns, marker, destination, *_args):
            token = (marker, destination)
            if token in calls:
                return False
            calls.add(token)
            return True
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": events}}
        env = {"GROUPED_DELIVERY_MODE": "true", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
               "HIGH_TOPIC_ARN": "high", "SLACK_TOPIC_ARN": "slack", "DELIVERY_TABLE_NAME": "table",
               "PAGING_POLICY": json.dumps({"ecr_emergency_vulnerability_ids": ["CVE-2026-10002"]})}
        with patch.dict(os.environ, env), patch.object(router, "_record_grouped", return_value=True), \
             patch.object(router, "_get_item", side_effect=get_item), \
             patch.object(router, "_publish_once", side_effect=publish_once):
            counts = router.route_event(event, type("Table", (), {"update_item": lambda *a, **k: None})(), object())
        self.assertEqual(counts["urgent"], 2)
        self.assertEqual(counts["urgent_slack"], 2)
        self.assertEqual(len({marker for marker, _ in calls}), 1)
        self.assertEqual({destination for _, destination in calls},
                         {"urgent", "urgent_slack", "critical", "critical_slack"})

    def test_old_remediation_alias_migrates_even_without_new_aws_timestamp(self):
        item = image_finding("CVE-2026-10001")
        old = router._compact_finding(item)
        old.pop("page_group")
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "table"}), \
             patch.object(router, "_get_item", return_value={"notification_payload": json.dumps(old),
                          "notification_updated_at": item["UpdatedAt"], "notification_state": "ACTIVE",
                          "notification_pending": "0"}):
            self.assertTrue(router._record_grouped(table, item))
        values = table.request["ExpressionAttributeValues"]
        migrated = json.loads(values[":payload"]["S"])
        self.assertEqual(migrated["previous_page_group_key"], old["group"]["key"])
        self.assertEqual(values[":pending"]["S"], "1")

    def test_slack_publish_failure_leaves_retry_state(self):
        with patch.object(router, "_claim", return_value="lease"), patch.object(router, "_finish") as finish:
            class FailingSNS:
                def publish(self, **_kwargs):
                    raise RuntimeError("SNS unavailable")
            with self.assertRaisesRegex(RuntimeError, "SNS unavailable"):
                router._publish_once(object(), FailingSNS(), "group#key", "urgent_slack", "arn:test", {}, 10)
        self.assertFalse(finish.call_args.args[-1])

    def test_opsgenie_rate_limit_exhaustion_is_not_silent(self):
        failure = urllib.error.HTTPError("", 429, "rate limited", {}, None)
        with patch.dict(os.environ, {"OPSGENIE_API_URL": "https://api.opsgenie.com", "OPSGENIE_API_KEY": "test"}), \
             patch.object(notifier.urllib.request, "urlopen", side_effect=failure) as call, \
             patch.object(notifier.time, "sleep"):
            with self.assertRaises(urllib.error.HTTPError):
                notifier._request("POST", "/v2/alerts", {"alias": "test"})
        self.assertEqual(call.call_count, 4)

    def test_closed_opsgenie_alias_is_reopened_for_new_urgent_finding(self):
        finding = image_finding("CVE-2026-10001")
        group = router._compact_finding(finding)["page_group"]
        calls = []

        def request(method, path, payload=None):
            calls.append((method, path))
            return {"data": {"status": "closed", "priority": "P2"}} if method == "GET" else {"requestId": "ok"}

        with patch.object(notifier, "_request", side_effect=request), patch.object(notifier, "_wait_for_request"):
            notifier.deliver({"detail": {"findings": [finding]}, "_dasmeta_group_urgent": True,
                              "_dasmeta_group": group, "_dasmeta_page_priority": "P2"})
        self.assertEqual([method for method, _ in calls], ["GET", "POST"])
        self.assertEqual(calls[-1][1], "/v2/alerts")

    def test_existing_p2_incident_adds_new_cve_without_new_alert(self):
        records = [router._compact_finding(image_finding("CVE-2026-10001")),
                   router._compact_finding(image_finding("CVE-2026-10002"))]
        summary = digest.summarize_group(records, identity="page_group")
        state = {"opsgenie_open": "1", "opsgenie_priority": "P2", "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": "old-signature", "opsgenie_last_update_at": "2026-11-04T08:00:00Z"}
        with patch.object(digest, "_ops_action") as action, patch.object(digest, "_set_fields"):
            digest.sync_opsgenie(object(), summary, state, 1793782800)
        paths = [call.args[1] for call in action.call_args_list]
        self.assertFalse(any(path == "/v2/alerts" or "/notes?" in path for path in paths))
        self.assertTrue(any("/description?" in path for path in paths))
        self.assertIn("CVE-2026-10002", digest._opsgenie_description(summary))

    def test_active_findings_prevent_quiet_period_closure(self):
        record = router._compact_finding(image_finding("CVE-2026-10001"))
        record["page_priority"] = None
        summary = digest.summarize_group([record], identity="page_group")
        with patch.object(digest, "_close_opsgenie_alias") as close, patch.object(digest, "_set_fields") as set_fields:
            digest.sync_opsgenie(object(), summary, {"opsgenie_open": "1", "opsgenie_no_urgent_since": "2026-11-01T08:00:00Z"}, 1793782800)
        close.assert_not_called()
        set_fields.assert_not_called()

    def test_reconciliation_paginates_high_volume_findings(self):
        class SecurityHub:
            calls = 0
            def get_findings(self, **kwargs):
                self.calls += 1
                return {"Findings": [{}] * 100, "NextToken": "page-2"} if self.calls == 1 else {"Findings": [{}] * 100}
        securityhub = SecurityHub()
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_record_grouped", return_value=True) as record:
            seen, changed, full = digest.reconcile_findings(object(), securityhub, 1793782800)
        self.assertEqual((seen, changed, full), (200, 200, True))
        self.assertEqual(record.call_count, 200)
        self.assertEqual(securityhub.calls, 2)

    def test_ten_critical_cves_render_as_one_application_digest_entry(self):
        records = [router._compact_finding(image_finding(f"CVE-2026-{number:05d}")) for number in range(10000, 10010)]
        for record in records:
            record["pending"] = True
        groups = {record["group"]["key"]: [record] for record in records}
        payloads = []
        with patch.dict(os.environ, {"DAILY_DIGEST_MAX_GROUPS": "5"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: payloads.append(summary)), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), groups, 1793782800)
        summary = payloads[0]
        self.assertEqual(summary["active_count"], 10)
        self.assertEqual(summary["top_groups"], [])
        self.assertEqual(len(summary["application_summaries"]), 1)
        self.assertEqual(summary["application_summaries"][0]["vulnerabilities"], 10)
        self.assertEqual(summary["application_summaries"][0]["images"], 1)


if __name__ == "__main__":
    unittest.main()
