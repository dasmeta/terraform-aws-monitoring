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
        set_fields.assert_not_called()

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
             patch.object(digest, "_get_item", return_value={}), \
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
             patch.object(digest, "_get_item", return_value={}), \
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
             patch.object(digest, "_get_item", return_value={}), \
             patch.object(digest, "scan_findings") as scan, \
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
