import importlib.util
import copy
import json
import os
import pathlib
import sys
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

from botocore.exceptions import ClientError


ROOT = pathlib.Path(__file__).parents[1] / "modules/security-hub/functions"
sys.path.insert(0, str(ROOT))
SPEC = importlib.util.spec_from_file_location("finding_router", ROOT / "finding_router.py")
ROUTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ROUTER)

SPEC = importlib.util.spec_from_file_location("group_digest", ROOT / "group_digest.py")
DIGEST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DIGEST)


def finding(identifier, state="ACTIVE", severity="HIGH", ami="ami-123", pool="general", updated="2026-11-01T12:00:00Z"):
    return {
        "Id": identifier,
        "AwsAccountId": "111122223333",
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "ProductName": "Inspector",
        "CreatedAt": "2026-10-31T12:00:00Z",
        "UpdatedAt": updated,
        "RecordState": state,
        "Workflow": {"Status": "NEW"},
        "Title": "CVE-2026-56855 - golang.org/x/crypto",
        "Severity": {"Label": severity},
        "Vulnerabilities": [{"Id": "CVE-2026-56855", "ExploitAvailable": "NO"}],
        "Resources": [{
            "Type": "AwsEc2Instance",
            "Id": "arn:aws:ec2:eu-central-1:111122223333:instance/" + identifier,
            "Tags": {"kubernetes.io/cluster/example-prod": "owned", "karpenter.sh/nodepool": pool},
            "Details": {"AwsEc2Instance": {"ImageId": ami}},
        }],
    }


class GroupedFindingTests(unittest.TestCase):
    def test_same_remediation_groups_different_nodes_and_new_image_separates(self):
        a = ROUTER._group_identity(finding("i-one"))
        b = ROUTER._group_identity(finding("i-two"))
        c = ROUTER._group_identity(finding("i-three", ami="ami-456"))
        self.assertEqual(a["key"], b["key"])
        self.assertNotEqual(a["key"], c["key"])
        self.assertIn("example-prod", a["label"])

    def test_unknown_image_or_pool_is_kept_separate(self):
        self.assertNotEqual(
            ROUTER._group_identity(finding("i-one", ami=None))["key"],
            ROUTER._group_identity(finding("i-two", ami=None))["key"],
        )
        self.assertNotEqual(
            ROUTER._group_identity(finding("i-one", pool=None))["key"],
            ROUTER._group_identity(finding("i-two", pool=None))["key"],
        )

    def test_group_summary_keeps_every_new_finding_in_count_and_uses_active_members_for_close(self):
        active = ROUTER._compact_finding(finding("i-one"))
        archived = ROUTER._compact_finding(finding("i-two", state="ARCHIVED"))
        group = DIGEST.summarize_group([active, archived])
        self.assertEqual(group["new_count"], 2)
        self.assertEqual(group["active_count"], 1)
        self.assertEqual(group["high_count"], 1)
        self.assertEqual(group["affected_resources"], 1)
        self.assertIsNone(group["priority"])
        self.assertFalse(group["cleared"])
        self.assertEqual(group["new_severities"]["HIGH"], 2)

    def test_exploitable_high_escalates_and_archive_does_not_close_other_active_member(self):
        first = ROUTER._compact_finding(finding("i-one"))
        first["exploit_available"] = "YES"
        second = ROUTER._compact_finding(finding("i-two"))
        group = DIGEST.summarize_group([first, second])
        self.assertEqual(group["priority"], "P1")
        self.assertFalse(group["cleared"])
        first["record_state"] = "ARCHIVED"
        group = DIGEST.summarize_group([first, second])
        self.assertIsNone(group["priority"])
        self.assertEqual(group["high_count"], 1)
        self.assertFalse(group["cleared"])


class FakeTable:
    def __init__(self):
        self.items = {}

    def get_item(self, **request):
        key = request["Key"]["finding_key"]["S"]
        return {"Item": {name: {"S": value} for name, value in self.items.get(key, {}).items()}}

    def update_item(self, **request):
        key = request["Key"]["finding_key"]["S"]
        item = self.items.setdefault(key, {})
        names = request["ExpressionAttributeNames"]
        values = request.get("ExpressionAttributeValues", {})
        expression = request["UpdateExpression"]
        if expression.startswith("SET #state = :pending"):
            state = names["#state"]
            if item.get(state) == "SENT":
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
            item[state] = "PENDING"
            item[names["#lease"]] = values[":lease"]["N"]
            item[names["#token"]] = values[":token"]["S"]
            return
        if expression.startswith("SET #state = :state REMOVE"):
            state = names["#state"]
            item[state] = values[":state"]["S"]
            item.pop(names["#lease"], None)
            item.pop(names["#token"], None)
            return
        if expression.startswith("REMOVE #state"):
            for name in names.values():
                item.pop(name, None)
            return
        condition = request.get("ConditionExpression", "")
        if "attribute_not_exists" in condition and item.get("notification_updated_at", "") >= values[":updated"]["S"]:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
        if condition == "#updated = :updated" and item.get("notification_updated_at") != values[":updated"]["S"]:
            raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
        for symbolic, name in names.items():
            suffix = symbolic.removeprefix("#")
            symbolic_value = ":v" + suffix[1:] if suffix.startswith("n") and suffix[1:].isdigit() else ":done" if suffix == "pending" and ":done" in values else ":" + suffix
            if symbolic_value in values:
                item[name] = values[symbolic_value]["S"]

    def scan(self, **request):
        return {"Items": [{name: {"S": value} for name, value in item.items()} for item in self.items.values()]}


class FakeSecurityHub:
    def __init__(self, findings):
        self.findings = findings

    def get_findings(self, **request):
        start = datetime.fromisoformat(request["Filters"]["UpdatedAt"][0]["Start"])
        end = datetime.fromisoformat(request["Filters"]["UpdatedAt"][0]["End"])
        return {"Findings": [finding for finding in self.findings if start <= datetime.fromisoformat(finding["UpdatedAt"].replace("Z", "+00:00")) <= end]}


class FakeSns:
    def __init__(self):
        self.messages = []

    def publish(self, **request):
        self.messages.append(json.loads(request["Message"]))


class GroupedFlowTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {
            "DELIVERY_TABLE_NAME": "finding-ledger",
            "FINDING_CUTOVER_AT": "2026-10-30T00:00:00Z",
            "GROUPED_DELIVERY_MODE": "true",
            "SLACK_TOPIC_ARN": "arn:aws:sns:eu-central-1:111122223333:security",
            "HIGH_TOPIC_ARN": "arn:aws:sns:eu-central-1:111122223333:opsgenie",
            "OPSGENIE_ALERT_PREFIX": "SPM",
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.table = FakeTable()
        self.sns = FakeSns()
        self.now = int(datetime(2026, 11, 1, 13, 0, tzinfo=timezone.utc).timestamp())

    def test_reconciliation_recovers_missed_event_and_replay_sends_nothing(self):
        one = finding("i-one")
        two = finding("i-two")
        self.assertEqual(ROUTER.route_event({"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [one]}}, self.table, self.sns)["recorded"], 1)
        self.assertEqual(self.sns.messages, [])
        calls = []
        with patch.object(DIGEST, "_ops_action", side_effect=lambda *args: calls.append(args)):
            first = DIGEST.run(self.table, FakeSecurityHub([one, two]), self.sns, now=self.now)
            second = DIGEST.run(self.table, FakeSecurityHub([one, two]), self.sns, now=self.now + 900)
        self.assertEqual(first["reconciled"], 2)
        self.assertEqual(first["changed"], 1)
        self.assertEqual(first["slack_digests"], 1)
        self.assertEqual(second["slack_digests"], 0)
        self.assertEqual(self.sns.messages[0]["_dasmeta_group_digest"]["new_count"], 2)
        self.assertEqual(len([call for call in calls if call[1] == "/v2/alerts"]), 0)
        self.assertEqual(sum("notification_kind" in value for value in self.table.items.values()), 2)

    def test_one_archived_node_keeps_group_open_then_last_archive_closes_once(self):
        one = finding("i-one")
        two = finding("i-two")
        hub = FakeSecurityHub([one, two])
        calls = []
        with patch.object(DIGEST, "_ops_action", side_effect=lambda *args: calls.append(args)):
            DIGEST.run(self.table, hub, self.sns, now=self.now)
            one["RecordState"] = "ARCHIVED"
            one["UpdatedAt"] = "2026-11-01T13:10:00Z"
            DIGEST.run(self.table, hub, self.sns, now=self.now + 900)
            self.assertFalse(any("/close?" in call[1] for call in calls))
            two["RecordState"] = "ARCHIVED"
            two["UpdatedAt"] = "2026-11-01T13:20:00Z"
            DIGEST.run(self.table, hub, self.sns, now=self.now + 86400)
            DIGEST.run(self.table, hub, self.sns, now=self.now + 87300)
        self.assertEqual(len([call for call in calls if "/close?" in call[1]]), 0)
        self.assertEqual(len(self.sns.messages), 2)
        self.assertEqual(self.sns.messages[-1]["_dasmeta_group_digest"]["groups_cleared_total"], 1)

    def test_urgent_findings_page_once_per_group_before_digest(self):
        one = finding("i-one", severity="CRITICAL")
        two = finding("i-two", severity="CRITICAL")
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [one, two]}}
        first = ROUTER.route_event(event, self.table, self.sns, now=self.now)
        second = ROUTER.route_event(event, self.table, self.sns, now=self.now + 10)
        self.assertEqual(first["urgent"], 1)
        self.assertEqual(second["urgent"], 0)
        self.assertEqual(len(self.sns.messages), 2)
        self.assertTrue(self.sns.messages[0]["_dasmeta_group_urgent"])
        self.assertEqual(first["urgent_slack"], 1)
        self.assertEqual(second["urgent_slack"], 0)
        self.assertEqual(sum("notification_kind" in value for value in self.table.items.values()), 2)

    def test_low_exploitable_finding_stays_in_slack_digest_without_opsgenie(self):
        low = finding("i-one", severity="LOW")
        low["Vulnerabilities"][0]["ExploitAvailable"] = "YES"
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [low]}}
        result = ROUTER.route_event(event, self.table, self.sns, now=self.now)
        self.assertEqual(result["recorded"], 1)
        self.assertEqual(result["urgent"], 0)

    def test_archive_without_image_keeps_original_group_and_stale_urgent_replay_is_ignored(self):
        original = finding("i-one", severity="CRITICAL")
        event = lambda item: {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [item]}}
        ROUTER.route_event(event(original), self.table, self.sns, now=self.now)
        old_group = json.loads(self.table.items[ROUTER._finding_key(original)]["notification_payload"])["group"]["key"]
        archived = copy.deepcopy(original)
        archived["RecordState"] = "ARCHIVED"
        archived["UpdatedAt"] = "2026-11-01T13:10:00Z"
        archived["Resources"][0]["Tags"] = {}
        archived["Resources"][0]["Details"] = {}
        ROUTER.route_event(event(archived), self.table, self.sns, now=self.now + 900)
        new_group = json.loads(self.table.items[ROUTER._finding_key(original)]["notification_payload"])["group"]["key"]
        self.assertEqual(old_group, new_group)
        DIGEST._clear_urgent_claim(self.table, "group#" + old_group)
        stale = ROUTER.route_event(event(original), self.table, self.sns, now=self.now + 1000)
        self.assertEqual(stale["urgent"], 0)
        self.assertEqual(len(self.sns.messages), 2)

    def test_legacy_per_finding_alert_closes_after_group_alert_exists(self):
        one = finding("i-one")
        key = ROUTER._finding_key(one)
        self.table.items[key] = {"opsgenie_delivery_mode": "API", "opsgenie_state": "SENT"}
        calls = []
        with patch.object(DIGEST, "_ops_action", side_effect=lambda *args: calls.append(args)):
            result = DIGEST.run(self.table, FakeSecurityHub([one]), self.sns, now=self.now)
        self.assertEqual(result["legacy_alerts_migrated"], 1)
        self.assertEqual(self.table.items[key]["legacy_group_migrated"], "1")
        self.assertEqual(len([call for call in calls if call[1] == "/v2/alerts"]), 0)
        self.assertEqual(len([call for call in calls if "/close?" in call[1]]), 1)

    def test_first_run_combines_multiple_groups_into_one_slack_baseline(self):
        hub = FakeSecurityHub([finding("i-one", ami="ami-123"), finding("i-two", ami="ami-456")])
        calls = []
        with patch.object(DIGEST, "_ops_action", side_effect=lambda *args: calls.append(args)):
            result = DIGEST.run(self.table, hub, self.sns, now=self.now)
        self.assertEqual(result["groups"], 2)
        self.assertEqual(result["slack_digests"], 1)
        self.assertEqual(len([call for call in calls if call[1] == "/v2/alerts"]), 0)
        self.assertIn("2 remediation groups", self.sns.messages[0]["_dasmeta_group_digest"]["label"])

    def test_subsequent_new_fallback_findings_share_one_slack_digest(self):
        first = finding("i-one", ami=None)
        with patch.object(DIGEST, "_ops_action"):
            DIGEST.run(self.table, FakeSecurityHub([first]), self.sns, now=self.now)
            second = finding("i-two", ami=None, updated="2026-11-01T13:10:00Z")
            third = finding("i-three", ami=None, updated="2026-11-01T13:10:00Z")
            early = DIGEST.run(self.table, FakeSecurityHub([first, second, third]), self.sns, now=self.now + 900)
            result = DIGEST.run(self.table, FakeSecurityHub([first, second, third]), self.sns, now=self.now + 86400)
        self.assertEqual(early["slack_digests"], 0)
        self.assertEqual(result["slack_digests"], 1)
        self.assertEqual(len(self.sns.messages), 2)
        digest = self.sns.messages[-1]["_dasmeta_group_digest"]
        self.assertEqual(digest["new_count"], 2)
        self.assertEqual(digest["groups_changed_total"], 2)
        self.assertEqual(len(digest["groups_changed"]), 2)

    def test_opsgenie_failure_does_not_block_slack_and_is_retried(self):
        one = finding("i-one", severity="CRITICAL")
        hub = FakeSecurityHub([one])
        with patch.object(DIGEST, "_ops_action", side_effect=RuntimeError("Opsgenie 403")):
            with self.assertRaisesRegex(RuntimeError, "Opsgenie group actions failed"):
                DIGEST.run(self.table, hub, self.sns, now=self.now)
        self.assertEqual(len(self.sns.messages), 1)
        self.assertEqual(self.table.items[ROUTER._finding_key(one)]["notification_pending"], "0")
        calls = []
        with patch.object(DIGEST, "_ops_action", side_effect=lambda *args: calls.append(args)):
            DIGEST.run(self.table, hub, self.sns, now=self.now + 900)
        self.assertEqual(len(self.sns.messages), 1)
        self.assertEqual(len([call for call in calls if call[1] == "/v2/alerts"]), 1)

    def test_severity_escalation_is_in_next_digest_but_archive_is_not(self):
        low = finding("i-one", severity="LOW")
        with patch.object(DIGEST, "_ops_action"):
            DIGEST.run(self.table, FakeSecurityHub([low]), self.sns, now=self.now)
        key = ROUTER._finding_key(low)
        self.assertEqual(self.table.items[key]["notification_pending"], "0")
        high = copy.deepcopy(low)
        high["Severity"]["Label"] = "HIGH"
        high["UpdatedAt"] = "2026-11-01T13:10:00Z"
        ROUTER._record_grouped(self.table, high)
        self.assertEqual(self.table.items[key]["notification_pending"], "1")
        archived = copy.deepcopy(high)
        archived["RecordState"] = "ARCHIVED"
        archived["UpdatedAt"] = "2026-11-01T13:20:00Z"
        ROUTER._record_grouped(self.table, archived)
        self.assertEqual(self.table.items[key]["notification_pending"], "1")

    def test_information_only_is_counted_once_daily_and_never_pages(self):
        first = finding("control-one", severity="INFORMATIONAL")
        first["Compliance"] = {"Status": "PASSED"}
        first["RecordState"] = "ARCHIVED"
        second = finding("control-two", severity="INFORMATIONAL", updated="2026-11-01T13:10:00Z")
        second["Compliance"] = {"Status": "NOT_AVAILABLE"}
        with patch.object(DIGEST, "_ops_action") as actions:
            DIGEST.run(self.table, FakeSecurityHub([first]), self.sns, now=self.now)
            DIGEST.run(self.table, FakeSecurityHub([first, second]), self.sns, now=self.now + 900)
            DIGEST.run(self.table, FakeSecurityHub([first, second]), self.sns, now=self.now + 86400)
        self.assertEqual(len(self.sns.messages), 2)
        self.assertEqual([message["_dasmeta_group_digest"]["routine_count"] for message in self.sns.messages], [1, 1])
        self.assertEqual([message["_dasmeta_group_digest"]["new_count"] for message in self.sns.messages], [0, 0])
        self.assertFalse(any(call.args[1] == "/v2/alerts" for call in actions.call_args_list))

    def test_high_without_exploit_does_not_page_and_existing_p2_closes(self):
        record = ROUTER._compact_finding(finding("i-one"))
        summary = DIGEST.summarize_group([record])
        self.assertIsNone(summary["priority"])
        marker = "group#" + summary["group"]["key"]
        self.table.items[marker] = {"opsgenie_open": "1", "opsgenie_priority": "P2"}
        with patch.object(DIGEST, "_ops_action") as action:
            DIGEST.sync_opsgenie(self.table, summary, dict(self.table.items[marker]), self.now)
        self.assertEqual(action.call_count, 1)
        self.assertIn("/close?", action.call_args.args[1])
        self.assertEqual(self.table.items[marker]["opsgenie_open"], "0")

    def test_urgent_title_names_patch_target_and_fallback_names_finding(self):
        grouped = ROUTER._compact_finding(finding("i-one", severity="CRITICAL"))
        message = DIGEST._opsgenie_message(DIGEST.summarize_group([grouped]))
        self.assertIn("Patch example-prod/general node image ami-123", message)
        self.assertNotIn("resources", message)
        fallback = ROUTER._compact_finding(finding("i-one", severity="CRITICAL", pool=None))
        message = DIGEST._opsgenie_message(DIGEST.summarize_group([fallback]))
        self.assertIn("CVE-2026-56855", message)
        self.assertIn("i-one", message)


if __name__ == "__main__":
    unittest.main()
