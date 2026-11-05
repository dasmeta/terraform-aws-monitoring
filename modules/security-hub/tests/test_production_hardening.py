"""Production regression cases for grouped Security Hub delivery."""

import json
import os
import pathlib
import sys
import unittest
import urllib.error
import zlib
from copy import deepcopy
from datetime import datetime, timezone
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


class DailyLedger:
    """Small conditional DynamoDB fixture for daily delivery fault injection."""

    def __init__(self):
        self.items = {}
        self.fail_checkpoint_once = False
        self.fail_group_once = False

    @staticmethod
    def error(code):
        return ClientError({"Error": {"Code": code, "Message": code}}, "UpdateItem")

    def get_item(self, **request):
        key = request["Key"]["finding_key"]["S"]
        return {"Item": deepcopy(self.items[key])} if key in self.items else {}

    def put_item(self, **request):
        row = deepcopy(request["Item"])
        key = row["finding_key"]["S"]
        existing = self.items.get(key)
        if request.get("ConditionExpression") and existing and not (
                existing["daily_state"]["S"] == "DONE" and
                existing["daily_day"]["S"] < row["daily_day"]["S"]):
            raise self.error("ConditionalCheckFailedException")
        self.items[key] = row

    def delete_item(self, **request):
        self.items.pop(request["Key"]["finding_key"]["S"], None)

    def update_item(self, **request):
        key = request["Key"]["finding_key"]["S"]
        row = self.items.get(key, {"finding_key": {"S": key}})
        condition = request.get("ConditionExpression", "")
        values = request["ExpressionAttributeValues"]
        if key == digest.DAILY_OUTBOX_KEY and ":ready" in values:
            if row.get("daily_id") != values[":id"] or not (
                    row["daily_state"]["S"] == "READY" or
                    row["daily_state"]["S"] == "CLAIMED" and
                    int(row["daily_lease"]["N"]) <= int(values[":now"]["N"])):
                raise self.error("ConditionalCheckFailedException")
        elif key == digest.DAILY_OUTBOX_KEY and ":owner" in values:
            if row.get("daily_id") != values[":id"] or row.get("daily_owner") != values[":owner"]:
                raise self.error("ConditionalCheckFailedException")
        elif key == "group#checkpoint" and "#last" in request["ExpressionAttributeNames"]:
            if self.fail_checkpoint_once:
                self.fail_checkpoint_once = False
                raise self.error("InternalServerError")
            old = row.get("last_daily_slack_at")
            if old != values.get(":old") or old and ":old" not in values:
                raise self.error("ConditionalCheckFailedException")
        elif ":revision" in values:
            if row.get("notification_digest_pending") != values[":one"] or \
                    row.get("notification_pending_at") != values[":revision"]:
                raise self.error("ConditionalCheckFailedException")
        elif key.startswith("group#") and key != "group#checkpoint" and self.fail_group_once:
            self.fail_group_once = False
            raise self.error("InternalServerError")
        names = request["ExpressionAttributeNames"]
        for term in request["UpdateExpression"].removeprefix("SET ").split(", "):
            name, value = term.split(" = ")
            row[names[name]] = deepcopy(values[value])
        self.items[key] = row


class AcceptedSns:
    def __init__(self):
        self.messages = []
        self.crash_after_accept = False

    def publish(self, **request):
        self.messages.append(json.loads(request["Message"]))
        if self.crash_after_accept:
            self.crash_after_accept = False
            raise RuntimeError("Lambda stopped after SNS accepted the message")
        return {"MessageId": str(len(self.messages))}


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
    @staticmethod
    def daily_groups(records):
        groups, pages = {}, {}
        for record in records:
            blob = zlib.compress(json.dumps(record).encode())
            groups.setdefault(record["group"]["key"], []).append(blob)
            pages.setdefault(record["page_group"]["key"], []).append(blob)
        return digest.PackedGroups(groups), digest.PackedGroups(pages)

    @staticmethod
    def daily_record(identifier="first", revision="2026-11-04T08:01:00Z"):
        finding = image_finding(identifier)
        finding["Id"] = finding["Id"].replace("b" * 32, ("b" if identifier == "first" else "c") * 32)
        record = router._compact_finding(finding)
        record.update(pending=True, _ledger_revision=revision, _digest_pending_explicit=True,
                      change_kind="new")
        return record

    def test_daily_outbox_replays_same_snapshot_when_checkpoint_fails_after_sns(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        groups, pages = self.daily_groups([self.daily_record()])
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        ledger.fail_checkpoint_once = True
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            with self.assertRaises(ClientError):
                digest.send_slack_batch_packed(ledger, sns, groups, pages, now)
            self.assertEqual(len(sns.messages), 1)
            self.assertNotIn("last_daily_slack_at", ledger.items.get("group#checkpoint", {}))
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1901):
            self.assertTrue(digest._deliver_daily_outbox(ledger, sns))
            self.assertFalse(digest._deliver_daily_outbox(ledger, sns))
        self.assertEqual(len(sns.messages), 2)
        self.assertEqual(sns.messages[0], sns.messages[1])
        self.assertEqual(sns.messages[0]["_dasmeta_group_digest"]["new_count"], 1)

    def test_daily_outbox_recovers_lambda_crash_after_sns_acceptance(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        groups, pages = self.daily_groups([self.daily_record()])
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        sns.crash_after_accept = True
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            with self.assertRaisesRegex(RuntimeError, "Lambda stopped"):
                digest.send_slack_batch_packed(ledger, sns, groups, pages, now)
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1901):
            self.assertTrue(digest._deliver_daily_outbox(ledger, sns))
        self.assertEqual(len(sns.messages), 2)
        self.assertEqual(sns.messages[0]["_dasmeta_daily_delivery_id"],
                         sns.messages[1]["_dasmeta_daily_delivery_id"])

    def test_overlapping_daily_invocation_cannot_publish_same_claim(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        groups, pages = self.daily_groups([self.daily_record()])
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        original_publish = sns.publish
        overlapping = []
        def publish(**request):
            overlapping.append(digest._deliver_daily_outbox(ledger, sns))
            return original_publish(**request)
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000), \
             patch.object(sns, "publish", side_effect=publish):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now))
        self.assertEqual(overlapping, [False])
        self.assertEqual(len(sns.messages), 1)

    def test_group_state_failure_after_publish_retries_without_republishing(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        groups, pages = self.daily_groups([self.daily_record()])
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        ledger.fail_group_once = True
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            with self.assertRaises(ClientError):
                digest.send_slack_batch_packed(ledger, sns, groups, pages, now)
        self.assertEqual(len(sns.messages), 1)
        self.assertIn("last_daily_slack_at", ledger.items["group#checkpoint"])
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1901):
            self.assertTrue(digest._deliver_daily_outbox(ledger, sns))
        self.assertEqual(len(sns.messages), 1)
        self.assertEqual(ledger.items["group#" + self.daily_record()["group"]["key"]]["slack_open"]["S"], "1")

    def test_new_finding_during_digest_stays_new_for_next_daily_snapshot(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        first = self.daily_record()
        late = self.daily_record("second", "2026-11-04T09:00:01Z")
        for record in (first, late):
            ledger.items[record["finding_key"]] = {
                "finding_key": {"S": record["finding_key"]},
                "notification_digest_pending": {"S": "1"},
                "notification_pending_at": {"S": record["_ledger_revision"]},
            }
        groups, pages = self.daily_groups([first, late])
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now))
        self.assertEqual(sns.messages[0]["_dasmeta_group_digest"]["new_count"], 1)
        self.assertEqual(ledger.items[first["finding_key"]]["notification_digest_pending"]["S"], "0")
        self.assertEqual(ledger.items[late["finding_key"]]["notification_digest_pending"]["S"], "1")
        first["pending"] = False
        groups, pages = self.daily_groups([first, late])
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=2000):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now + 86400))
        self.assertEqual(sns.messages[1]["_dasmeta_group_digest"]["new_count"], 1)
        self.assertEqual(ledger.items[late["finding_key"]]["notification_digest_pending"]["S"], "0")

    def test_gsi_late_finding_remains_pending_after_watermark(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        first = self.daily_record()
        omitted = self.daily_record("second", "2026-11-04T08:30:00Z")
        for record in (first, omitted):
            ledger.items[record["finding_key"]] = {
                "finding_key": {"S": record["finding_key"]},
                "notification_digest_pending": {"S": "1"},
                "notification_pending_at": {"S": record["_ledger_revision"]},
            }
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        groups, pages = self.daily_groups([first])  # GSI omitted the second row.
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now))
        self.assertEqual(ledger.items[omitted["finding_key"]]["notification_digest_pending"]["S"], "1")
        first["pending"] = False
        groups, pages = self.daily_groups([first, omitted])
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=2000):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now + 86400))
        self.assertEqual(sns.messages[1]["_dasmeta_group_digest"]["new_count"], 1)
        self.assertEqual(ledger.items[omitted["finding_key"]]["notification_digest_pending"]["S"], "0")

    def test_index_reader_keeps_unacknowledged_gsi_row_new_after_watermark(self):
        record = self.daily_record()
        row = {"finding_key": {"S": record["finding_key"]},
               "notification_kind": {"S": "finding"},
               "notification_payload": {"S": json.dumps(record)},
               "notification_state": {"S": "ACTIVE"},
               "notification_digest_pending": {"S": "1"},
               "notification_pending_at": {"S": "2026-11-04T08:30:00Z"}}
        class Table:
            def query(self, **request):
                return {"Items": [row] if request["ExpressionAttributeValues"][":state"]["S"] == "ACTIVE" else []}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            groups, _, _, _ = digest.scan_findings_indexed(
                Table(), "2026-11-04T09:00:00Z", int(datetime(2026, 11, 5, 9, tzinfo=timezone.utc).timestamp()))
        self.assertTrue(next(iter(groups.values()))[0]["pending"])

    def test_daily_outbox_chunks_10001_new_finding_acknowledgements(self):
        ledger, sns = DailyLedger(), AcceptedSns()
        template = self.daily_record()
        records = []
        for index in range(10001):
            record = {**template, "finding_key": f"finding-{index}"}
            records.append(record)
            ledger.items[record["finding_key"]] = {
                "finding_key": {"S": record["finding_key"]},
                "notification_digest_pending": {"S": "1"},
                "notification_pending_at": {"S": record["_ledger_revision"]},
            }
        groups, pages = self.daily_groups(records)
        now = int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "SLACK_TOPIC_ARN": "test-topic"}), \
             patch.object(digest.time, "time", return_value=1000):
            self.assertTrue(digest.send_slack_batch_packed(ledger, sns, groups, pages, now))
        self.assertEqual(len(sns.messages), 1)
        self.assertEqual(sns.messages[0]["_dasmeta_group_digest"]["new_count"], 10001)
        self.assertEqual(ledger.items[digest.DAILY_OUTBOX_KEY]["daily_ack_chunks"]["N"], "21")
        self.assertEqual(ledger.items[digest.DAILY_OUTBOX_KEY]["daily_state"]["S"], "DONE")
        self.assertTrue(all(ledger.items[record["finding_key"]]["notification_digest_pending"]["S"] == "0"
                            for record in records))

    def test_bounded_reconciliation_resumes_page_and_window_without_replaying_completed_work(self):
        finding = image_finding()
        checkpoint = {}
        calls = []
        class Table:
            writes = []
            def update_item(self, **request):
                self.writes.append(request)
        class SecurityHub:
            def get_findings(self, **request):
                calls.append(request)
                start = request["Filters"]["UpdatedAt"][0]["Start"]
                if start.startswith("2026-11-04T08:00") and not request.get("NextToken"):
                    return {"Findings": [finding], "NextToken": "second-page"}
                return {"Findings": [finding]}
        now = int(datetime(2026, 11, 4, 8, 30, tzinfo=timezone.utc).timestamp())
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T08:00:00Z"}), \
             patch.object(digest, "RECONCILE_PAGES_PER_RUN", 1), \
             patch.object(digest, "_batch_get_findings", return_value={}), \
             patch.object(digest, "_record_grouped", return_value=False) as record:
            first = digest.reconcile_findings_bounded(table, SecurityHub(), now, checkpoint)
            self.assertFalse(first[3])
            self.assertEqual(checkpoint["reconcile_next_token"], "second-page")
            second = digest.reconcile_findings_bounded(table, SecurityHub(), now + 900, checkpoint)
            self.assertFalse(second[3])
            self.assertTrue(checkpoint["reconcile_cursor"].startswith("2026-11-04T08:15"))
            third = digest.reconcile_findings_bounded(table, SecurityHub(), now + 1800, checkpoint)
        self.assertTrue(third[3])
        self.assertEqual(checkpoint["reconciled_through"], "2026-11-04T08:30:00+00:00")
        self.assertEqual(checkpoint["reconcile_target"], "")
        self.assertEqual([call.get("NextToken") for call in calls], [None, "second-page", None])
        self.assertEqual(record.call_count, 3)
        self.assertEqual(len(table.writes), 3)
        self.assertTrue(all("#version" in write["ConditionExpression"] for write in table.writes))

    def test_expired_reconciliation_token_restarts_only_its_window(self):
        checkpoint = {"reconcile_version": "old", "reconcile_cursor": "2026-11-04T08:00:00+00:00",
                      "reconcile_target": "2026-11-04T08:15:00+00:00", "reconcile_next_token": "expired",
                      "reconcile_full": "1"}
        class Table:
            def update_item(self, **_request):
                pass
        class SecurityHub:
            calls = []
            def get_findings(self, **request):
                self.calls.append(request)
                if request.get("NextToken"):
                    raise ClientError({"Error": {"Code": "InvalidInputException", "Message": "expired"}}, "GetFindings")
                return {"Findings": []}
        hub = SecurityHub()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T08:00:00Z"}):
            self.assertFalse(digest.reconcile_findings_bounded(Table(), hub, 1793781000, checkpoint)[3])
            self.assertEqual(checkpoint["reconcile_next_token"], "")
            self.assertTrue(digest.reconcile_findings_bounded(Table(), hub, 1793781000, checkpoint)[3])
        self.assertEqual([call.get("NextToken") for call in hub.calls], ["expired", None])

    def test_concurrent_cursor_write_fails_without_advancing_checkpoint(self):
        checkpoint = {"reconcile_version": "old", "reconciled_through": "2026-11-03T08:00:00Z"}
        class Table:
            def update_item(self, **_request):
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException", "Message": "race"}}, "UpdateItem")
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            with self.assertRaisesRegex(RuntimeError, "changed concurrently"):
                digest._save_reconcile_progress(Table(), checkpoint, {"reconcile_cursor": "new"})
        self.assertNotIn("reconcile_cursor", checkpoint)

    def test_bounded_reconciliation_retries_security_hub_limit_error(self):
        checkpoint = {}
        class Table:
            def update_item(self, **_request):
                pass
        class SecurityHub:
            calls = 0
            def get_findings(self, **_request):
                self.calls += 1
                if self.calls == 1:
                    raise ClientError({"Error": {"Code": "LimitExceededException", "Message": "rate"}}, "GetFindings")
                return {"Findings": []}
        hub = SecurityHub()
        now = int(datetime(2026, 11, 4, 8, 15, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T08:00:00Z"}), \
             patch.object(digest.time, "sleep"):
            self.assertTrue(digest.reconcile_findings_bounded(Table(), hub, now, checkpoint)[3])
        self.assertEqual(hub.calls, 2)

    def test_parallel_scan_retries_one_segment_without_skipping_pages(self):
        first = router._compact_finding(image_finding())
        second = dict(first, finding_key="second")
        third = dict(first, finding_key="third")
        def row(record):
            return {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
                    "notification_payload": {"S": json.dumps(record)}}
        class Table:
            calls = []
            throttled = False
            def scan(self, **request):
                segment = request["Segment"]
                token = bool(request.get("ExclusiveStartKey"))
                self.calls.append((segment, token))
                if segment == 0 and not token and not self.throttled:
                    self.throttled = True
                    raise ClientError({"Error": {"Code": "ProvisionedThroughputExceededException", "Message": "retry"}}, "Scan")
                if segment == 0 and not token:
                    return {"Items": [row(first)], "LastEvaluatedKey": {"finding_key": {"S": "one"}}}
                return {"Items": [row(second if segment == 0 else third)]}
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest.time, "sleep"):
            groups, _, _, _ = digest.scan_findings(table, packed=True, segments=2)
        self.assertEqual(sum(len(records) for records in groups.values()), 3)
        self.assertEqual(table.calls.count((0, False)), 2)
        self.assertIn((0, True), table.calls)
        self.assertIn((1, False), table.calls)

    def test_populated_legacy_ledger_survives_bootstrap_and_index_queries(self):
        first = router._compact_finding(image_finding())
        second_finding = image_finding("second")
        second_finding["Id"] = second_finding["Id"].replace("b" * 32, "c" * 32).replace("123456789012", "210987654321")
        second_finding["AwsAccountId"] = "210987654321"
        second_finding["Resources"][0]["Id"] = second_finding["Resources"][0]["Id"].replace("123456789012", "210987654321")
        second = router._compact_finding(second_finding)
        inactive = dict(first, finding_key="archived-finding", record_state="ARCHIVED", workflow="RESOLVED")
        orphan = {**first["page_group"], "key": "old-open-incident"}
        def row(record, state, **fields):
            return {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
                    "notification_payload": {"S": json.dumps(record)}, "notification_state": {"S": state},
                    "notification_pending": {"S": "1"},
                    "notification_pending_at": {"S": "2026-11-04T08:10:00Z"},
                    **{key: {"S": value} for key, value in fields.items()}}
        class Table:
            def __init__(self):
                self.rows = [row(first, "ACTIVE"), row(second, "ACTIVE"),
                             row(inactive, "ARCHIVED", opsgenie_delivery_mode="API", opsgenie_state="SENT"),
                             {"finding_key": {"S": "group#old-open-incident"},
                              "notification_state": {"S": "OPEN_MARKER"}, "opsgenie_open": {"S": "1"},
                              "opsgenie_group_payload": {"S": json.dumps(orphan)},
                              "opsgenie_group_updated_at": {"S": "2026-11-04T08:01:00Z"}}]
                self.fail_second_page = 0
            def scan(self, **request):
                if request.get("ExclusiveStartKey") and self.fail_second_page:
                    self.fail_second_page -= 1
                    raise ClientError({"Error": {"Code": "ProvisionedThroughputExceededException", "Message": "retry"}}, "Scan")
                if request.get("ExclusiveStartKey"):
                    return {"Items": self.rows[2:]}
                return {"Items": self.rows[:2], "LastEvaluatedKey": {"finding_key": {"S": "page-2"}}}
            def query(self, **request):
                state = request["ExpressionAttributeValues"][":state"]["S"]
                return {"Items": [item for item in self.rows if item.get("notification_state", {}).get("S") == state]}
            def update_item(self, **request):
                key = request["Key"]["finding_key"]["S"]
                target = next(item for item in self.rows if item["finding_key"]["S"] == key)
                self_outer.assertEqual(target["notification_payload"], request["ExpressionAttributeValues"][":payload"])
                target["notification_state"] = {"S": "LEGACY_PENDING"}
        self_outer = self
        table = Table()
        now = int(datetime(2026, 11, 4, 12, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest.time, "sleep"):
            table.fail_second_page = 3
            with self.assertRaises(ClientError):
                digest.scan_findings(table, packed=True, index_legacy=True)
            groups, pages, active, _ = digest.scan_findings(table, packed=True, index_legacy=True)
            indexed, indexed_pages, indexed_active, _ = digest.scan_findings_indexed(
                table, "2026-11-04T08:00:00Z", now)
        self.assertEqual(sum(len(records) for records in groups.values()), 3)
        self.assertIn("old-open-incident", active)
        self.assertEqual(table.rows[2]["notification_state"]["S"], "LEGACY_PENDING")
        self.assertEqual(sum(len(records) for records in indexed.values()), 4)
        self.assertIn("old-open-incident", indexed_active)
        self.assertEqual(indexed_pages["old-open-incident"][0]["record_state"], "ARCHIVED")
        self.assertNotEqual(first["page_group"]["key"], second["page_group"]["key"])

    def test_router_records_multi_finding_batch_without_slow_inspector_calls(self):
        findings = []
        for index in range(20):
            item = image_finding(f"CVE-{index}")
            item["Id"] = item["Id"].replace("b" * 32, f"{index:032x}")
            findings.append(item)
        event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported",
                 "detail": {"findings": findings}}
        calls = []
        def record(_table, _finding, **kwargs):
            calls.append(kwargs)
            return True
        with patch.dict(os.environ, {"GROUPED_DELIVERY_MODE": "true",
                                  "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(router, "_record_grouped", side_effect=record), \
             patch.object(router, "_get_item", return_value={}), \
             patch.object(router, "_inspector_ecr_evidence",
                          side_effect=AssertionError("slow or throttled lookup ran in router")):
            result = router.route_event(event, object(), object())
        self.assertEqual(result["recorded"], 20)
        self.assertEqual(calls, [{"lookup_inspector": False}] * 20)

    def test_router_persists_unknown_and_worker_can_enrich_later(self):
        item = image_finding()
        class Table:
            writes = []
            def update_item(self, **request):
                self.writes.append(request)
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test",
                                  "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(router, "_get_item", return_value={}), \
             patch.object(router, "_inspector_ecr_evidence",
                          side_effect=AssertionError("router called Inspector")):
            self.assertTrue(router._record_grouped(table, item, lookup_inspector=False))
        first = json.loads(table.writes[-1]["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(first["risk_context"]["deployment"], "unknown")
        current = {"notification_payload": json.dumps(first), "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_digest_pending": "1", "notification_state": "ACTIVE"}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test",
                                  "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router, "_inspector_ecr_evidence", return_value={
                 "deployment": "observed_in_use", "checked_at": "2026-11-05T08:00:00Z"}) as lookup:
            self.assertTrue(router._record_grouped(table, item))
        lookup.assert_called_once_with(item)
        enriched = json.loads(table.writes[-1]["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(enriched["risk_context"]["deployment"], "observed_in_use")

    def test_recent_reconciliation_defers_inspector_reads_to_bounded_pass(self):
        class SecurityHub:
            def get_findings(self, **_request):
                return {"Findings": [image_finding()]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z",
                                  "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(digest, "_batch_get_findings", return_value={}), \
             patch.object(digest, "_record_grouped", return_value=True) as record:
            self.assertEqual(digest.reconcile_recent_findings(
                object(), SecurityHub(), int(datetime(2026, 11, 4, 9, tzinfo=timezone.utc).timestamp())), (1, 1))
        self.assertFalse(record.call_args.kwargs["lookup_inspector"])

    def test_bounded_reconciliation_halves_page_size_with_inspector_lookup(self):
        class Table:
            def update_item(self, **_request):
                pass
        class SecurityHub:
            page_size = None
            def get_findings(self, **request):
                self.page_size = request["MaxResults"]
                return {"Findings": []}
        hub = SecurityHub()
        now = int(datetime(2026, 11, 4, 8, 15, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T08:00:00Z",
                                  "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}):
            self.assertTrue(digest.reconcile_findings_bounded(Table(), hub, now, {})[3])
        self.assertEqual(hub.page_size, 50)

    def test_application_incident_lifecycle_has_one_create_until_reopen(self):
        def record(number, digest_char, verified=None):
            item = image_finding(f"CVE-2026-{number:05d}")
            item["Id"] = item["Id"].replace("b" * 32, f"{number:032x}")
            item["Resources"][0]["Id"] = item["Resources"][0]["Id"].replace("a" * 64, digest_char * 64)
            item["Vulnerabilities"][0]["Id"] = f"CVE-2026-{number:05d}"
            return router._compact_finding(item, verified)
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production", "QUIET_PERIOD_SECONDS": "3600"}):
            first, second, third = record(1, "a"), record(2, "b"), record(3, "c")
            self.assertEqual(len({item["page_group"]["key"] for item in (first, second, third)}), 1)
            state = {}
            actions = []
            priorities = []
            closed = []
            def save(_table, _key, fields):
                state.update(fields)
            def action(method, path, body):
                actions.append((method, path, body))
            def send(records, at):
                summary = digest.summarize_group(records, identity="page_group")
                digest.sync_opsgenie(object(), summary, state.copy(), at)
            with patch.object(digest, "_request", return_value={"data": {}}), \
                 patch.object(digest, "_ops_action", side_effect=action), \
                 patch.object(digest, "_ensure_opsgenie_priority", side_effect=lambda *args: priorities.append(args)), \
                 patch.object(digest, "_close_opsgenie_alias", side_effect=lambda *args: closed.append(args)), \
                 patch.object(digest, "_set_fields", side_effect=save), \
                 patch.object(digest, "_clear_critical_claim"), patch.object(digest, "_clear_urgent_claim"):
                send([first, second], 1793782800)
                send([first, second], 1793782801)  # duplicate event
                send([first, second, third], 1793782802)  # new CVE, third image
                escalated = record(3, "c", {"deployment": "observed_in_use", "exposure": "exposed"})
                send([first, second, escalated], 1793782803)
                send([first, second, third], 1793782804)  # P1 to P2
                archived = {**first, "record_state": "ARCHIVED", "workflow": "RESOLVED"}
                send([archived, second, third], 1793782805)  # partial resolution
                all_archived = [{**item, "record_state": "ARCHIVED", "workflow": "RESOLVED"}
                                for item in (first, second, third)]
                send(all_archived, 1793782806)
                send(all_archived, 1793786407)  # quiet period elapsed
                send([record(4, "d")], 1793786408)  # reopen
        creates = [entry for entry in actions if entry[0] == "POST" and entry[1] == "/v2/alerts"]
        self.assertEqual(len(creates), 2)
        self.assertEqual([entry[2]["priority"] for entry in creates], ["P2", "P2"])
        self.assertEqual([entry[1] for entry in priorities], ["P1", "P2"])
        self.assertEqual(len(closed), 1)
        self.assertEqual(len([entry for entry in actions if entry[0] == "PUT" and "/message" in entry[1]]), 2)
        self.assertEqual(len([entry for entry in actions if entry[0] == "POST" and "/details" in entry[1]]), 4)
        self.assertFalse(any("/notes" in entry[1] for entry in actions))

    def test_pending_watermark_keeps_late_finding_with_old_source_timestamp(self):
        first = router._compact_finding(image_finding())
        second = dict(first, finding_key="second")
        def row(record, pending_at):
            return {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
                    "notification_payload": {"S": json.dumps(record)}, "notification_pending": {"S": "1"},
                    "notification_pending_at": {"S": pending_at}}
        class Table:
            def scan(self, **_request):
                return {"Items": [row(first, "2026-11-04T08:00:00Z"),
                                  row(second, "2026-11-04T10:00:00Z")]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            groups, _, _, _ = digest.scan_findings(Table(), packed=True,
                                                     pending_after="2026-11-04T09:00:00Z")
        pending = {record["finding_key"]: record["pending"] for records in groups.values() for record in records}
        self.assertEqual(pending, {first["finding_key"]: False, "second": True})

    def test_trivial_update_does_not_rearm_acknowledged_pending_marker(self):
        original = image_finding()
        previous = router._compact_finding(original)
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": original["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(original["UpdatedAt"])),
                   "notification_pending": "1", "notification_pending_at": "2026-11-04T08:02:00Z",
                   "notification_digest_pending": "1",
                   "notification_state": "ACTIVE"}
        updated = dict(original, UpdatedAt="2026-11-04T08:03:00Z")
        class Table:
            request = None
            def update_item(self, **request):
                self.request = request
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), \
             patch.object(router, "_get_item", return_value=current):
            self.assertTrue(router._record_grouped(table, updated))
        values = table.request["ExpressionAttributeValues"]
        self.assertEqual(values[":pending"]["S"], "1")
        self.assertEqual(values[":pending_at"]["S"], current["notification_pending_at"])
        self.assertNotIn("notification_digest_pending", table.request["ExpressionAttributeNames"].values())

    def test_policy_change_rearms_pending_marker_after_daily_watermark(self):
        finding = image_finding()
        previous = router._compact_finding(finding)
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": finding["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(finding["UpdatedAt"])),
                   "notification_pending": "1", "notification_pending_at": "2026-11-04T08:02:00Z",
                   "notification_state": "ACTIVE"}
        class Table:
            request = None
            def update_item(self, **request):
                self.request = request
        table = Table()
        emergency = json.dumps({"ecr_emergency_vulnerability_ids": ["CVE-2026-10001"]})
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "PAGING_POLICY": emergency}), \
             patch.object(router, "_get_item", return_value=current):
            self.assertTrue(router._record_grouped(table, finding))
        self.assertNotEqual(table.request["ExpressionAttributeValues"][":pending_at"]["S"],
                            current["notification_pending_at"])

    def test_indexed_scan_pages_active_findings_and_preserves_open_marker(self):
        first = router._compact_finding(image_finding())
        second = dict(first, finding_key="second")
        orphan = {**first["page_group"], "key": "orphan", "label": "Open legacy incident"}
        def row(record):
            return {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
                    "notification_payload": {"S": json.dumps(record)}, "notification_state": {"S": "ACTIVE"}}
        class Table:
            calls = []
            def query(self, **request):
                state = request["ExpressionAttributeValues"][":state"]["S"]
                self.calls.append((state, bool(request.get("ExclusiveStartKey"))))
                if state == "ACTIVE" and not request.get("ExclusiveStartKey"):
                    return {"Items": [row(first)], "LastEvaluatedKey": {"finding_key": {"S": "first"}}}
                if state == "ACTIVE":
                    return {"Items": [row(second)]}
                if state == "OPEN_MARKER":
                    return {"Items": [{"finding_key": {"S": "group#orphan"},
                                       "opsgenie_open": {"S": "1"},
                                       "opsgenie_group_payload": {"S": json.dumps(orphan)},
                                       "opsgenie_group_updated_at": {"S": "2026-11-04T08:01:00Z"}}]}
                return {"Items": []}
        table = Table()
        now = int(datetime(2026, 11, 4, 12, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            groups, pages, active, _ = digest.scan_findings_indexed(table, "2026-11-04T09:00:00Z", now)
        self.assertEqual(sum(len(records) for records in groups.values()), 3)
        self.assertIn("orphan", active)
        self.assertEqual(pages["orphan"][0]["record_state"], "ARCHIVED")
        self.assertIn(("ACTIVE", True), table.calls)

    def test_packed_group_access_decodes_only_requested_finding(self):
        record = router._compact_finding(image_finding())
        blob = zlib.compress(json.dumps(record).encode())
        packed = digest.PackedRecords([blob] * 10000)
        with patch.object(digest.zlib, "decompress", wraps=zlib.decompress) as decompress:
            self.assertEqual(len(packed), 10000)
            self.assertEqual(decompress.call_count, 0)
            self.assertEqual(packed[0]["finding_key"], record["finding_key"])
            self.assertEqual(decompress.call_count, 1)

    def test_first_run_bootstraps_existing_ledger_before_reconciliation(self):
        checkpoint = {"reconciled_through": "2026-11-03T13:22:30Z",
                      "last_daily_slack_at": "2026-11-03T11:05:18Z"}
        empty = digest.PackedGroups({})
        now = int(datetime(2026, 11, 5, 9, 0, tzinfo=timezone.utc).timestamp())
        with patch.object(digest, "_get_item", return_value=checkpoint), \
             patch.object(digest, "scan_findings", return_value=(empty, empty, set(), set())) as scan, \
             patch.object(digest, "reconcile_findings_bounded", side_effect=AssertionError("bootstrap must run first")), \
             patch.object(digest, "_daily_due", return_value=True), \
             patch.object(digest, "send_slack_batch_packed", return_value=True), \
             patch.object(digest, "_set_fields") as write:
            result = digest.run(object(), object(), object(), now)
        self.assertTrue(result["ledger_bootstrap"])
        self.assertEqual(result["slack_digests"], 1)
        self.assertTrue(scan.call_args.kwargs["index_legacy"])
        self.assertTrue(any(call.args[2] == {"ledger_index_ready": "1"} for call in write.call_args_list))

    def test_superseded_closed_legacy_marker_does_not_block_bootstrap(self):
        checkpoint = {"reconciled_through": "2026-11-03T13:22:30Z",
                      "last_daily_slack_at": "2026-11-05T08:00:00Z"}
        marker = {"finding_key": {"S": "group#old"}, "opsgenie_open": {"S": "0"},
                  "superseded_group_closed": {"S": "1"}, "urgent_state": {"S": "SENT"}}

        class Table:
            def scan(self, **request):
                return {"Items": [marker], "ScannedCount": 1}

        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "DAILY_DIGEST_ENABLED": "false"}), \
             patch.object(digest, "LEDGER_SCAN_SEGMENTS", 1), \
             patch.object(digest, "_deliver_daily_outbox", return_value=False), \
             patch.object(digest, "_get_item", side_effect=lambda table, key: checkpoint if key == "group#checkpoint" else
                          {"opsgenie_open": "0", "superseded_group_closed": "1", "urgent_state": "SENT"}), \
             patch.object(digest, "_daily_due", return_value=False), \
             patch.object(digest, "_set_fields") as write:
            result = digest.run(Table(), object(), object(),
                                int(datetime(2026, 11, 5, 9, tzinfo=timezone.utc).timestamp()))
        self.assertTrue(result["ledger_bootstrap"])
        self.assertTrue(any(call.args[2] == {"ledger_index_ready": "1"} for call in write.call_args_list))

    def test_superseded_marker_with_open_incident_still_blocks_bootstrap(self):
        checkpoint = {"reconciled_through": "2026-11-03T13:22:30Z",
                      "last_daily_slack_at": "2026-11-05T08:00:00Z"}
        marker = {"finding_key": {"S": "group#old"}, "opsgenie_open": {"S": "1"},
                  "superseded_group_closed": {"S": "1"}}

        class Table:
            def scan(self, **request):
                return {"Items": [marker], "ScannedCount": 1}

        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "DAILY_DIGEST_ENABLED": "false"}), \
             patch.object(digest, "LEDGER_SCAN_SEGMENTS", 1), \
             patch.object(digest, "_deliver_daily_outbox", return_value=False), \
             patch.object(digest, "_get_item", side_effect=lambda table, key: checkpoint if key == "group#checkpoint" else
                          {"opsgenie_open": "1", "superseded_group_closed": "1"}), \
             patch.object(digest, "_daily_due", return_value=False), \
             patch.object(digest, "_set_fields") as write:
            with self.assertRaisesRegex(RuntimeError, "lacks an indexed snapshot"):
                digest.run(Table(), object(), object(),
                           int(datetime(2026, 11, 5, 9, tzinfo=timezone.utc).timestamp()))
        self.assertFalse(any(call.args[2].get("ledger_index_ready") == "1" for call in write.call_args_list))

    def test_externally_closed_marker_with_stale_claim_is_not_open(self):
        marker = {"finding_key": {"S": "group#closed"}, "opsgenie_open": {"S": "0"},
                  "opsgenie_external_closed_signature": {"S": "snapshot"}, "urgent_state": {"S": "SENT"}}

        class Table:
            def scan(self, **request):
                return {"Items": [marker], "ScannedCount": 1}

        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            _, _, active, _ = digest.scan_findings(Table(), packed=True, segments=1)
        self.assertNotIn("closed", active)

    def test_bootstrap_does_not_switch_to_index_before_old_pending_digest(self):
        checkpoint = {"last_daily_slack_at": "2026-11-03T11:05:18Z"}
        empty = digest.PackedGroups({})
        now = int(datetime(2026, 11, 5, 7, 0, tzinfo=timezone.utc).timestamp())
        with patch.object(digest, "_get_item", return_value=checkpoint), \
             patch.object(digest, "scan_findings", return_value=(empty, empty, set(), set())), \
             patch.object(digest, "_daily_due", return_value=False), \
             patch.object(digest, "_set_fields") as write:
            digest.run(object(), object(), object(), now)
        self.assertFalse(any(call.args[2].get("ledger_index_ready") == "1" for call in write.call_args_list))

    def test_recent_updates_are_reconciled_during_historical_replay(self):
        checkpoint = {"ledger_index_ready": "1", "reconcile_target": "2026-11-05T08:00:00Z",
                      "last_daily_slack_at": "2026-11-05T08:00:00Z"}
        empty = digest.PackedGroups({})
        now = int(datetime(2026, 11, 5, 9, 0, tzinfo=timezone.utc).timestamp())
        with patch.object(digest, "_get_item", return_value=checkpoint), \
             patch.object(digest, "reconcile_recent_findings", return_value=(3, 1)) as recent, \
             patch.object(digest, "reconcile_findings_bounded", return_value=(5, 2, True, False)), \
             patch.object(digest, "scan_findings_indexed", return_value=(empty, empty, set(), set())), \
             patch.object(digest, "_daily_due", return_value=False):
            result = digest.run(object(), object(), object(), now)
        recent.assert_called_once()
        self.assertEqual((result["reconciled"], result["changed"]), (8, 3))
        self.assertFalse(result["reconciliation_complete"])

    def test_index_duplicate_prefers_latest_archived_snapshot(self):
        active = router._compact_finding(image_finding())
        archived = dict(active, record_state="ARCHIVED", updated_at="2026-11-04T10:00:00Z")
        def row(record, revision):
            return {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
                    "notification_payload": {"S": json.dumps(record)},
                    "notification_pending_at": {"S": revision}}
        class Table:
            def query(self, **request):
                state = request["ExpressionAttributeValues"][":state"]["S"]
                if state == "ACTIVE":
                    return {"Items": [row(active, "2026-11-04T08:00:00Z")]}
                if state == "INACTIVE#2026-11-04":
                    return {"Items": [row(archived, "2026-11-04T10:00:00Z")]}
                return {"Items": []}
        now = int(datetime(2026, 11, 4, 12, tzinfo=timezone.utc).timestamp())
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            _, groups, _, _ = digest.scan_findings_indexed(Table(), "2026-11-04T09:00:00Z", now)
        records = list(next(groups.values()))
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["record_state"], "ARCHIVED")

    def test_failed_claim_clear_keeps_closed_incident_indexed_for_retry(self):
        summary = {"group": {"key": "group"}, "priority": None,
                   "latest_updated_at": "2026-11-04T08:00:00Z"}
        state = {"opsgenie_open": "1", "opsgenie_no_urgent_since": "2026-11-04T08:00:00Z",
                 "notification_state": "OPEN_MARKER"}
        with patch.object(digest, "_close_opsgenie_alias"), \
             patch.object(digest, "_clear_urgent_claim", side_effect=RuntimeError("DDB unavailable")), \
             patch.object(digest, "_set_fields") as write:
            with self.assertRaisesRegex(RuntimeError, "DDB unavailable"):
                digest.sync_opsgenie(object(), summary, state, 1793782800)
        self.assertFalse(any(call.args[2].get("notification_state") == "CLOSED_MARKER"
                             for call in write.call_args_list))

    def test_superseded_open_marker_placeholder_does_not_block_migration(self):
        groups = {"new": [{"finding_key": "finding-new", "previous_page_group_key": "old"}],
                  "old": [{"finding_key": "group#old"}]}
        def state(_table, key):
            return {"opsgenie_open": "1"} if key in {"group#new", "group#old"} else {}
        with patch.object(digest, "_get_item", side_effect=state), \
             patch.object(digest, "_close_opsgenie_alias") as close, \
             patch.object(digest, "_clear_urgent_claim"), \
             patch.object(digest, "_set_fields"):
            self.assertEqual(digest.migrate_previous_groups(object(), groups), 1)
        self.assertEqual(close.call_args.args[0], "securityhub-group-old")

    def test_legacy_index_backfill_uses_exact_snapshot_condition(self):
        row = {"finding_key": "finding", "notification_state": "ARCHIVED",
               "notification_payload": "original"}
        class Table:
            request = None
            def update_item(self, **request):
                self.request = request
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException", "Message": "newer event"}}, "UpdateItem")
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            digest._mark_legacy_index(table, row)
        self.assertIn("#payload = :payload", table.request["ConditionExpression"])
        self.assertEqual(table.request["ExpressionAttributeValues"][":payload"]["S"], "original")

    def test_missing_open_marker_snapshot_reverts_to_full_bootstrap(self):
        checkpoint = {"ledger_index_ready": "1", "last_daily_slack_at": "2026-11-05T08:00:00Z"}
        now = int(datetime(2026, 11, 5, 9, 0, tzinfo=timezone.utc).timestamp())
        with patch.object(digest, "_get_item", return_value=checkpoint), \
             patch.object(digest, "reconcile_findings_bounded", return_value=(0, 0, False, True)), \
             patch.object(digest, "scan_findings_indexed", side_effect=digest.MissingMarkerSnapshot("missing")), \
             patch.object(digest, "_set_fields") as write:
            with self.assertRaises(digest.MissingMarkerSnapshot):
                digest.run(object(), object(), object(), now)
        write.assert_called_once_with(unittest.mock.ANY, "group#checkpoint", {"ledger_index_ready": "0"})

    def test_packed_daily_digest_uses_one_watermark_without_per_finding_ack(self):
        record = router._compact_finding(image_finding())
        record["pending"] = True
        blob = zlib.compress(json.dumps(record).encode())
        groups = digest.PackedGroups({record["group"]["key"]: [blob]})
        pages = digest.PackedGroups({record["page_group"]["key"]: [blob]})
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_stage_daily_outbox") as stage, \
             patch.object(digest, "_deliver_daily_outbox", return_value=True), \
             patch.object(digest, "_acknowledge_pending_batch", side_effect=AssertionError("row writes are unbounded")), \
             patch.object(digest, "_set_fields"):
            digest.send_slack_batch_packed(object(), object(), groups, pages, 1793782800)
        stage.assert_called_once()


    def test_application_alias_isolated_by_account_region_project_and_environment(self):
        base = image_finding()
        cases = []
        for account, region, project, environment in (
            ("123456789012", "us-east-2", "alpha", "prod"),
            ("210987654321", "us-east-2", "alpha", "prod"),
            ("123456789012", "eu-west-1", "alpha", "prod"),
            ("123456789012", "us-east-2", "beta", "prod"),
            ("123456789012", "us-east-2", "alpha", "staging"),
        ):
            finding = json.loads(json.dumps(base))
            finding["AwsAccountId"] = account
            finding["Id"] = base["Id"].replace("123456789012", account).replace("us-east-2", region)
            finding["Resources"][0]["Id"] = base["Resources"][0]["Id"].replace("123456789012", account).replace("us-east-2", region)
            finding["Resources"][0]["Tags"] = {"Project": project, "Environment": environment}
            with patch.dict(os.environ, {"SECURITY_PROJECT": "", "SECURITY_ENVIRONMENT": ""}):
                cases.append(router._compact_finding(finding)["page_group"]["key"])
        self.assertEqual(len(set(cases)), len(cases))

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

    def test_inspector_use_and_missing_evidence_have_distinct_states(self):
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
            self.assertEqual(policy.paging_priority(item, {"deployment": "observed_in_use"}), "P2")
            self.assertEqual(policy.paging_priority(item, {"deployment": "observed_in_use", "exposure": "exposed"}), "P1")
        details["awsEcrContainerImage"]["inUseCount"] = 0
        self.assertEqual(router._inspector_ecr_evidence(item, Inspector([result]))["deployment"], "unknown")
        details["awsEcrContainerImage"]["inUseCount"] = 2
        details["awsEcrContainerImage"]["imageHash"] = "sha256:" + "c" * 64
        self.assertEqual(router._inspector_ecr_evidence(item, Inspector([result]))["deployment"], "unknown")

        class DeniedInspector:
            def list_findings(self, **_kwargs):
                raise RuntimeError("access denied")
        with patch.object(router.LOG, "warning") as warning:
            self.assertEqual(router._inspector_ecr_evidence(item, DeniedInspector()), {"deployment": "unknown"})
        warning.assert_called_once()

    def test_unchanged_finding_refreshes_expired_inspector_evidence(self):
        item = image_finding()
        previous = router._compact_finding(item, {"deployment": "observed_in_use", "checked_at": "2026-11-03T00:00:00Z"})
        current = {"notification_payload": json.dumps(previous), "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_pending": "0"}
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router, "_inspector_ecr_evidence", return_value={"deployment": "observed_in_use", "checked_at": "2026-11-05T08:00:00Z"}) as lookup, \
             patch.object(router.time, "time", return_value=1793865600):
            self.assertTrue(router._record_grouped(table, item))
        lookup.assert_called_once_with(item)
        stored = json.loads(table.request["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(stored["risk_context"]["deployment"], "observed_in_use")
        self.assertEqual(stored["deployment_evidence_at"], "2026-11-05T08:00:00Z")

    def test_failed_refresh_discards_prior_positive_evidence(self):
        item = image_finding()
        with patch.dict(os.environ, {"SECURITY_ENVIRONMENT": "Production"}):
            previous = router._compact_finding(item, {"deployment": "observed_in_use", "exposure": "exposed",
                                                     "checked_at": "2026-11-04T00:00:00Z"})
        self.assertEqual(previous["page_priority"], "P1")
        current = {"notification_payload": json.dumps(previous), "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"])),
                   "notification_pending": "0"}
        class Table:
            request = None
            def update_item(self, **kwargs):
                self.request = kwargs
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true",
                                  "SECURITY_ENVIRONMENT": "Production"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router, "_inspector_ecr_evidence", return_value={"deployment": "unknown"}), \
             patch.object(router.time, "time", return_value=1793865600):
            self.assertTrue(router._record_grouped(table, item))
        stored = json.loads(table.request["ExpressionAttributeValues"][":payload"]["S"])
        self.assertEqual(stored["risk_context"]["deployment"], "unknown")
        self.assertEqual(stored["deployment_evidence_at"], "")
        self.assertEqual(stored["page_priority"], "P2")
        self.assertEqual(table.request["ExpressionAttributeValues"][":pending"]["S"], "1")

    def test_fresh_inspector_evidence_is_reused_without_api_call(self):
        item = image_finding()
        previous = router._compact_finding(item, {"deployment": "observed_in_use", "checked_at": "2026-11-05T07:00:00Z"})
        current = {"notification_payload": json.dumps(previous), "notification_updated_at": item["UpdatedAt"],
                   "notification_updated_epoch": str(router._timestamp_micros(item["UpdatedAt"]))}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router, "_inspector_ecr_evidence") as lookup, \
             patch.object(router.time, "time", return_value=1793865600):
            self.assertFalse(router._record_grouped(object(), item))
        lookup.assert_not_called()

    def test_stale_inspector_event_does_not_refresh_or_overwrite_evidence(self):
        item = image_finding()
        previous = router._compact_finding(item)
        previous["updated_at"] = "2026-11-05T08:02:00Z"
        current = {"notification_payload": json.dumps(previous),
                   "notification_updated_at": previous["updated_at"]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(router, "_get_item", return_value=current), \
             patch.object(router, "_inspector_ecr_evidence") as lookup:
            self.assertFalse(router._record_grouped(object(), item))
        lookup.assert_not_called()

    def test_inspector_pagination_and_transient_throttle(self):
        item = image_finding()
        result = {"findingArn": item["Id"], "awsAccountId": item["AwsAccountId"], "resources": [{
            "type": "AWS_ECR_CONTAINER_IMAGE", "details": {"awsEcrContainerImage": {
                "repositoryName": "sample-api", "imageHash": "sha256:" + "a" * 64, "inUseCount": 1}}}]}
        class Inspector:
            calls = 0
            def list_findings(self, **kwargs):
                self.calls += 1
                if self.calls == 1:
                    raise ClientError({"Error": {"Code": "ThrottlingException", "Message": "slow down"}}, "ListFindings")
                if self.calls == 2:
                    return {"findings": [], "nextToken": "second"}
                self.assert_token = kwargs["nextToken"]
                return {"findings": [result]}
        inspector = Inspector()
        with patch.object(router.time, "sleep"):
            observed = router._inspector_ecr_evidence(item, inspector)
        self.assertEqual(observed["deployment"], "observed_in_use")
        self.assertEqual(inspector.calls, 3)
        self.assertEqual(inspector.assert_token, "second")

    def test_inspector_pagination_limit_preserves_unknown_for_retry(self):
        item = image_finding()
        class Inspector:
            calls = 0
            def list_findings(self, **_request):
                self.calls += 1
                return {"findings": [], "nextToken": f"page-{self.calls}"}
        inspector = Inspector()
        self.assertEqual(router._inspector_ecr_evidence(item, inspector), {"deployment": "unknown"})
        self.assertEqual(inspector.calls, 3)

    def test_slow_inspector_page_stops_before_another_request(self):
        item = image_finding()
        class Inspector:
            calls = 0
            def list_findings(self, **_request):
                self.calls += 1
                return {"findings": [], "nextToken": "second"}
        inspector = Inspector()
        with patch.object(router.time, "monotonic", side_effect=[0, 0, 0, 6]):
            self.assertEqual(router._inspector_ecr_evidence(item, inspector), {"deployment": "unknown"})
        self.assertEqual(inspector.calls, 1)

    def test_inspector_lookup_rejects_cross_account_region_and_partition(self):
        item = image_finding()
        class Inspector:
            def list_findings(self, **_kwargs):
                raise AssertionError("mismatched image must not be queried")
        for changed in (item["Resources"][0]["Id"].replace("123456789012", "210987654321"),
                        item["Resources"][0]["Id"].replace("us-east-2", "eu-west-1"),
                        item["Resources"][0]["Id"].replace("arn:aws:", "arn:aws-us-gov:")):
            mismatched = {**item, "Resources": [{**item["Resources"][0], "Id": changed}]}
            self.assertEqual(router._inspector_ecr_evidence(mismatched, Inspector()), {"deployment": "unknown"})

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
        self.assertFalse(any("opsgenie_priority" in call.args[2] for call in set_fields.call_args_list))

    def test_external_p2_close_suppresses_repeats_but_new_cve_reopens(self):
        summary = {"group": {"key": "application", "product": "Inspector"}, "priority": "P2",
                   "urgent_signature": "first", "urgent_count": 2, "active_count": 2,
                   "urgent_vulnerability_ids": ["CVE-1"]}
        state = {"opsgenie_open": "1", "opsgenie_priority": "P2",
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": "older"}

        def save(table, key, fields):
            state.update(fields)

        with patch.object(digest, "_set_fields", side_effect=save), \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"):
            with patch.object(digest, "_ops_action", side_effect=RuntimeError("Opsgenie rejected alert action: Alert does not exist")):
                digest.sync_opsgenie(object(), summary, state, 1793790000)
            self.assertEqual(state["opsgenie_open"], "0")
            self.assertEqual(state["notification_state"], "OPEN_MARKER")
            with patch.object(digest, "_ops_action") as action:
                digest.sync_opsgenie(object(), summary, state, 1793790001)
                digest.sync_opsgenie(object(), {**summary, "urgent_signature": "resolution", "urgent_count": 1},
                                    state, 1793790002)
            action.assert_not_called()
            self.assertEqual(state["opsgenie_external_closed_urgent_count"], "1")
            with patch.object(digest, "_request", side_effect=urllib.error.HTTPError("", 404, "missing", {}, None)), \
                 patch.object(digest, "_ops_action") as action:
                digest.sync_opsgenie(object(), {**summary, "urgent_signature": "new-cve", "urgent_count": 2,
                                                "urgent_vulnerability_ids": ["CVE-1", "CVE-2"]}, state, 1793790003)
            self.assertEqual([call.args[1] for call in action.call_args_list], ["/v2/alerts"])
            self.assertEqual(state["opsgenie_open"], "1")

    def test_closed_p2_escalation_creates_p1_and_retries_after_create_failure(self):
        summary = {"group": {"key": "application", "product": "Inspector"}, "priority": "P1",
                   "urgent_signature": "new-p1", "urgent_count": 2, "active_count": 2,
                   "urgent_vulnerability_ids": ["CVE-1", "CVE-2"]}
        state = {"opsgenie_open": "1", "opsgenie_priority": "P2",
                 "opsgenie_format_version": digest.OPSGENIE_FORMAT_VERSION,
                 "opsgenie_urgent_signature": "old-p2"}

        def save(table, key, fields):
            state.update(fields)

        missing = urllib.error.HTTPError("", 404, "missing", {}, None)
        with patch.object(digest, "_set_fields", side_effect=save), \
             patch.object(digest, "_ensure_opsgenie_priority", side_effect=missing), \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"), \
             patch.object(digest, "_ops_action", side_effect=RuntimeError("create failed")):
            with self.assertRaisesRegex(RuntimeError, "create failed"):
                digest.sync_opsgenie(object(), summary, state, 1793790000)
        self.assertEqual(state["opsgenie_open"], "0")
        self.assertEqual(state["opsgenie_external_closed_priority"], "P2")
        with patch.object(digest, "_set_fields", side_effect=save), \
             patch.object(digest, "_request", side_effect=urllib.error.HTTPError("", 404, "missing", {}, None)), \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"), \
             patch.object(digest, "_ops_action") as action:
            digest.sync_opsgenie(object(), summary, state, 1793790001)
        self.assertEqual([call.args[1] for call in action.call_args_list], ["/v2/alerts"])
        self.assertEqual(state["opsgenie_open"], "1")

    def test_resolved_external_close_allows_same_cve_in_new_episode(self):
        state = {"opsgenie_open": "0", "opsgenie_external_closed_signature": "old",
                 "opsgenie_external_closed_priority": "P2",
                 "opsgenie_external_closed_urgent_count": "1",
                 "opsgenie_external_closed_vulnerabilities": '["CVE-1"]',
                 "opsgenie_external_closed_vulnerability_total": "1"}

        def save(table, key, fields):
            state.update(fields)

        group = {"key": "application", "product": "Inspector"}
        with patch.object(digest, "_set_fields", side_effect=save):
            digest.sync_opsgenie(object(), {"group": group, "priority": None, "urgent_signature": "none"},
                                state, 1793790000)
        self.assertEqual(state["opsgenie_external_closed_signature"], "")
        with patch.object(digest, "_set_fields", side_effect=save), \
             patch.object(digest, "_request", side_effect=urllib.error.HTTPError("", 404, "missing", {}, None)), \
             patch.object(digest, "_opsgenie_message", return_value="message"), \
             patch.object(digest, "_opsgenie_details", return_value={}), \
             patch.object(digest, "_opsgenie_description", return_value="description"), \
             patch.object(digest, "_ops_action") as action:
            digest.sync_opsgenie(object(), {"group": group, "priority": "P2", "urgent_signature": "again",
                                            "urgent_count": 1, "active_count": 1,
                                            "urgent_vulnerability_ids": ["CVE-1"]}, state, 1793790001)
        self.assertEqual([call.args[1] for call in action.call_args_list], ["/v2/alerts"])

    def test_large_ledger_fails_explicitly_after_paginated_capacity_bound(self):
        """A bounded worker reports excess volume without advancing its checkpoint."""
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
                result = {"Items": [row] * 400, "ScannedCount": 400,
                          "ConsumedCapacity": {"CapacityUnits": 400.0}}
                if self.calls < 3:
                    result["LastEvaluatedKey"] = {"finding_key": {"S": str(self.calls)}}
                return result

        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test",
                                  "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest, "MAX_LEDGER_ITEMS", 1000):
            with self.assertRaisesRegex(RuntimeError, "exceeded 1000 items"):
                digest.scan_findings(table, packed=True)
        self.assertEqual(table.calls, 3)
        self.assertEqual(table.assert_request["ReturnConsumedCapacity"], "TOTAL")

    def test_reconcile_ten_thousand_findings_and_retry_throttled_page(self):
        base_finding = image_finding()
        class Table:
            def batch_get_item(self, **_request):
                return {"Responses": {}, "UnprocessedKeys": {}}
        class SecurityHub:
            calls = 0
            throttled = False
            def get_findings(self, **request):
                self.calls += 1
                page = int(request.get("NextToken", "0"))
                if page == 36 and not self.throttled:
                    self.throttled = True
                    raise ClientError({"Error": {"Code": "ThrottlingException", "Message": "retry"}}, "GetFindings")
                response = {"Findings": [{**base_finding, "Id": f"finding-{page * 100 + index}"}
                                         for index in range(100)]}
                if page < 99:
                    response["NextToken"] = str(page + 1)
                return response
        securityhub = SecurityHub()
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z", "DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_record_grouped", return_value=False) as record, \
             patch.object(digest.time, "sleep"):
            seen, changed, full = digest.reconcile_findings(Table(), securityhub, 1793782800)
        self.assertEqual((seen, changed, full), (10000, 0, True))
        self.assertEqual(record.call_count, 10000)
        self.assertEqual(securityhub.calls, 101)

    def test_bounded_replay_resumes_ten_thousand_findings_after_throttle(self):
        base = image_finding()
        class Table:
            def update_item(self, **_request):
                pass
        class SecurityHub:
            calls = 0
            throttled = False
            def get_findings(self, **request):
                self.calls += 1
                self_outer.assertEqual(request["MaxResults"], 50)
                page = int(request.get("NextToken", "0"))
                if page == 36 and not self.throttled:
                    self.throttled = True
                    raise ClientError({"Error": {"Code": "ThrottlingException", "Message": "retry"}}, "GetFindings")
                result = {"Findings": [{**base, "Id": f"finding-{page * 50 + index}"}
                                       for index in range(50)]}
                if page < 199:
                    result["NextToken"] = str(page + 1)
                return result
        self_outer = self
        hub = SecurityHub()
        checkpoint = {}
        now = int(datetime(2026, 11, 4, 8, 15, tzinfo=timezone.utc).timestamp())
        results = []
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T08:00:00Z",
                                  "DELIVERY_TABLE_NAME": "test", "ECR_DEPLOYMENT_LOOKUP_ENABLED": "true"}), \
             patch.object(digest, "RECONCILE_PAGES_PER_RUN", 30), \
             patch.object(digest, "_batch_get_findings", return_value={}), \
             patch.object(digest, "_record_grouped", return_value=False) as record, \
             patch.object(digest.time, "sleep"):
            for _ in range(7):
                results.append(digest.reconcile_findings_bounded(Table(), hub, now, checkpoint))
        self.assertEqual(sum(result[0] for result in results), 10000)
        self.assertTrue(results[-1][3])
        self.assertTrue(all(not result[3] for result in results[:-1]))
        self.assertEqual(record.call_count, 10000)
        self.assertEqual(hub.calls, 201)
        self.assertEqual(checkpoint["reconcile_target"], "")

    def test_reconcile_retries_unprocessed_batch_reads_before_accepting_page(self):
        finding = image_finding()
        class SecurityHub:
            def get_findings(self, **_request):
                return {"Findings": [finding]}
        class Table:
            calls = 0
            def batch_get_item(self, **request):
                self.calls += 1
                self.last_request = request
                if self.calls == 1:
                    return {"Responses": {}, "UnprocessedKeys": request["RequestItems"],
                            "ConsumedCapacity": [{"CapacityUnits": 0.5}]}
                return {"Responses": {"test": [{"finding_key": {"S": router._finding_key(finding)},
                                                 "notification_payload": {"S": "existing"}}]},
                        "UnprocessedKeys": {}, "ConsumedCapacity": [{"CapacityUnits": 1.0}]}
        table = Table()
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z", "DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_get_item", return_value={"ledger_index_ready": "1"}), \
             patch.object(digest, "_record_grouped", return_value=False) as record, \
             patch.object(digest.LOG, "info") as log, \
             patch.object(digest.time, "sleep"):
            self.assertEqual(digest.reconcile_findings(table, SecurityHub(), 1793782800)[0], 1)
        self.assertEqual(table.calls, 2)
        self.assertEqual(table.last_request["ReturnConsumedCapacity"], "TOTAL")
        self.assertEqual(record.call_args.kwargs["current"]["notification_payload"], "existing")
        self.assertEqual(log.call_args.args[4], 1.5)

    def test_unprocessed_batch_key_aborts_before_checkpoint(self):
        finding = image_finding()
        class SecurityHub:
            def get_findings(self, **_request):
                return {"Findings": [finding]}
        class Table:
            calls = 0
            def batch_get_item(self, **request):
                self.calls += 1
                return {"Responses": {}, "UnprocessedKeys": request["RequestItems"]}
        table = Table()
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z", "DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_get_item", return_value={"ledger_index_ready": "1"}), \
             patch.object(digest, "_record_grouped") as record, \
             patch.object(digest, "_set_fields") as write, \
             patch.object(digest.time, "sleep"):
            with self.assertRaisesRegex(RuntimeError, "finding keys unprocessed"):
                digest.run(table, SecurityHub(), object(), 1793782800)
        self.assertEqual(table.calls, 5)
        record.assert_not_called()
        write.assert_not_called()

    def test_exhausted_reconciliation_throttle_does_not_advance_checkpoint(self):
        class SecurityHub:
            calls = 0
            def get_findings(self, **_request):
                self.calls += 1
                raise ClientError({"Error": {"Code": "ThrottlingException", "Message": "retry"}}, "GetFindings")
        securityhub = SecurityHub()
        with patch.dict(os.environ, {"FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest, "_get_item", return_value={"ledger_index_ready": "1"}), \
             patch.object(digest, "scan_findings_indexed") as scan, \
             patch.object(digest, "_set_fields") as write, \
             patch.object(digest.time, "sleep"):
            with self.assertRaises(ClientError):
                digest.run(object(), securityhub, object(), 1793782800)
        self.assertEqual(securityhub.calls, 3)
        scan.assert_not_called()
        write.assert_not_called()

    def test_ledger_scan_retries_throttled_page_without_skipping_it(self):
        record = router._compact_finding(image_finding())
        row = {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
               "notification_payload": {"S": json.dumps(record)}}
        class Table:
            requests = []
            def scan(self, **request):
                self.requests.append(request)
                if len(self.requests) == 2:
                    raise ClientError({"Error": {"Code": "ProvisionedThroughputExceededException",
                                                 "Message": "retry"}}, "Scan")
                if len(self.requests) == 1:
                    return {"Items": [row], "LastEvaluatedKey": {"finding_key": {"S": "cursor"}}}
                return {"Items": [row]}
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest.time, "sleep"):
            records, _, _ = digest.scan_findings(table)
        self.assertEqual(len(records), 2)
        self.assertEqual(len(table.requests), 3)
        self.assertEqual(table.requests[1]["ExclusiveStartKey"], table.requests[2]["ExclusiveStartKey"])

    def test_packed_scan_decodes_only_requested_groups(self):
        first = router._compact_finding(image_finding())
        second_finding = image_finding()
        second_finding["Id"] = second_finding["Id"].replace("b" * 32, "c" * 32)
        second_finding["Vulnerabilities"][0]["Id"] = "CVE-2026-10002"
        second = router._compact_finding(second_finding)
        class Table:
            def scan(self, **_request):
                return {"Items": [{"finding_key": {"S": record["finding_key"]},
                                   "notification_kind": {"S": "finding"},
                                   "notification_payload": {"S": json.dumps(record)}}
                                  for record in (first, second)]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}):
            groups, page_groups, _, _ = digest.scan_findings(Table(), packed=True)
        self.assertEqual(len(groups), 2)
        self.assertEqual(len(page_groups), 1)
        self.assertEqual(len(page_groups[next(iter(page_groups))]), 2)
        self.assertEqual({item["finding_key"] for _, records in groups.items() for item in records},
                         {first["finding_key"], second["finding_key"]})

    def test_oversized_application_group_fails_explicitly(self):
        record = router._compact_finding(image_finding())
        row = {"finding_key": {"S": record["finding_key"]}, "notification_kind": {"S": "finding"},
               "notification_payload": {"S": json.dumps(record)}}
        class Table:
            def scan(self, **_request):
                return {"Items": [row, row]}
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test", "FINDING_CUTOVER_AT": "2026-11-04T07:00:00Z"}), \
             patch.object(digest, "MAX_GROUP_ITEMS", 1):
            with self.assertRaisesRegex(RuntimeError, "group exceeded 1 findings"):
                digest.scan_findings(Table(), packed=True)

    def test_packed_daily_digest_matches_existing_small_group_output(self):
        first = router._compact_finding(image_finding())
        second_finding = image_finding()
        second_finding["Id"] = second_finding["Id"].replace("b" * 32, "c" * 32)
        second_finding["Vulnerabilities"][0]["Id"] = "CVE-2026-10002"
        second = router._compact_finding(second_finding)
        for record in (first, second):
            record["pending"] = True
            record["_ledger_payload"] = json.dumps(record)
        groups = {record["group"]["key"]: [record] for record in (first, second)}
        page_groups = {first["page_group"]["key"]: [first, second]}
        def pack(mapping):
            return digest.PackedGroups({key: [digest.zlib.compress(json.dumps(record).encode()) for record in records]
                                        for key, records in mapping.items()})
        captured = []
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "_publish_slack", side_effect=lambda _sns, summary: captured.append(digest._slack_payload(summary, False))), \
             patch.object(digest, "_stage_daily_outbox", side_effect=lambda _table, summary, _changes, _pending, _now: captured.append(digest._slack_payload(summary, False))), \
             patch.object(digest, "_deliver_daily_outbox", return_value=True), \
             patch.object(digest, "_acknowledge_new"), patch.object(digest, "_set_fields"):
            digest.send_slack_batch(object(), object(), groups, 1793782800)
            digest.send_slack_batch_packed(object(), object(), pack(groups), pack(page_groups), 1793782800)
        self.assertEqual(captured[0], captured[1])

    def test_pending_ack_uses_bounded_conditional_transactions(self):
        class Table:
            batches = []
            def transact_write_items(self, **request):
                self.batches.append(request["TransactItems"])
            def update_item(self, **_request):
                raise AssertionError("successful transaction needs no per-finding write")
        table = Table()
        records = ({"finding_key": f"{index:064x}", "updated_at": "2026-11-04T08:01:00Z",
                    "_ledger_payload": f"payload-{index}"} for index in range(150))
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}):
            digest._acknowledge_pending_batch(table, records)
        self.assertEqual([len(batch) for batch in table.batches], [100, 50])
        self.assertEqual(table.batches[0][0]["Update"]["ExpressionAttributeValues"][":payload"]["S"], "payload-0")

    def test_transaction_conflict_falls_back_to_exact_snapshot_updates(self):
        record = {"finding_key": "finding", "updated_at": "2026-11-04T08:01:00Z",
                  "_ledger_payload": "original"}
        class Table:
            def transact_write_items(self, **_request):
                raise ClientError({"Error": {"Code": "TransactionCanceledException", "Message": "conflict"}}, "TransactWriteItems")
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), \
             patch.object(digest, "_acknowledge_new") as fallback:
            digest._acknowledge_pending_batch(Table(), [record])
        fallback.assert_called_once_with(unittest.mock.ANY, [record])

    def test_exhausted_transaction_throttle_keeps_pending_ack_retryable(self):
        record = {"finding_key": "finding", "updated_at": "2026-11-04T08:01:00Z",
                  "_ledger_payload": "original"}
        class Table:
            calls = 0
            def transact_write_items(self, **_request):
                self.calls += 1
                raise ClientError({"Error": {"Code": "ThrottlingException", "Message": "retry"}}, "TransactWriteItems")
        table = Table()
        with patch.dict(os.environ, {"DELIVERY_TABLE_NAME": "test"}), patch.object(digest.time, "sleep"):
            with self.assertRaises(ClientError):
                digest._acknowledge_pending_batch(table, [record])
        self.assertEqual(table.calls, 3)

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
             patch.object(digest, "_retire_legacy_index"), \
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
