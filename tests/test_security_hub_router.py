import importlib.util
import json
import os
import pathlib
import unittest
from unittest.mock import patch

from botocore.exceptions import ClientError


SOURCE = pathlib.Path(__file__).parents[1] / "modules/security-hub/functions/finding_router.py"
SPEC = importlib.util.spec_from_file_location("finding_router", SOURCE)
ROUTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ROUTER)


class FakeTable:
    def __init__(self):
        self.items = {}

    def update_item(self, **kwargs):
        key = kwargs["Key"]["finding_key"]["S"]
        item = self.items.setdefault(key, {})
        names = kwargs["ExpressionAttributeNames"]
        values = kwargs["ExpressionAttributeValues"]
        expression = kwargs["UpdateExpression"]
        if expression.startswith("SET #life = :closed"):
            if item.get("lifecycle") == "CLOSED" or item.get("slack_state") != "SENT" or item.get("episode_started_at", "") >= values[":updated"]["S"]:
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
            item["lifecycle"] = "CLOSED"
            item["resolved_at"] = values[":updated"]["S"]
            return
        if expression.startswith("SET #life = :open"):
            if item.get("lifecycle") != "CLOSED" or item.get("resolved_at") != values[":resolved"]["S"] or item["resolved_at"] >= values[":updated"]["S"]:
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException"}}, "UpdateItem")
            item["lifecycle"] = "OPEN"
            item["episode_started_at"] = values[":updated"]["S"]
            for field in ("slack_state", "opsgenie_state", "slack_resolution_state", "opsgenie_resolution_state", "opsgenie_delivery_mode"):
                item.pop(field, None)
            return
        state_name, lease_name, token_name = (names[x] for x in ("#state", "#lease", "#token"))
        if kwargs["UpdateExpression"].startswith("SET #state = :pending"):
            current = item.get(state_name)
            now = int(values[":now"]["N"])
            wrong_lifecycle = "#life" in names and (
                (values[":life"]["S"] == "CLOSED" and item.get("lifecycle") != "CLOSED")
                or (values[":life"]["S"] == "OPEN" and item.get("lifecycle") == "CLOSED")
            )
            if wrong_lifecycle or current == "SENT" or (current == "PENDING" and item.get(lease_name, now + 1) >= now):
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException", "Message": "claimed"}}, "UpdateItem")
            item[state_name] = "PENDING"
            item[lease_name] = int(values[":lease"]["N"])
            item[token_name] = values[":token"]["S"]
            if "#mode" in names:
                item[names["#mode"]] = values[":mode"]["S"]
        else:
            if item.get(state_name) != "PENDING" or item.get(token_name) != values[":token"]["S"]:
                raise ClientError({"Error": {"Code": "ConditionalCheckFailedException", "Message": "not owner"}}, "UpdateItem")
            item[state_name] = values[":state"]["S"]
            item.pop(lease_name, None)
            item.pop(token_name, None)

    def get_item(self, **kwargs):
        item = self.items.get(kwargs["Key"]["finding_key"]["S"], {})
        return {"Item": {key: {"S": value} for key, value in item.items() if isinstance(value, str)}}


class FakeSns:
    def __init__(self):
        self.published = []
        self.fail_topic = None

    def publish(self, **kwargs):
        if kwargs["TopicArn"] == self.fail_topic:
            raise RuntimeError("SNS unavailable")
        self.published.append(kwargs)


def finding(identifier="finding-1", severity="LOW", created="2026-10-31T00:00:00Z"):
    return {
        "Id": identifier,
        "ProductArn": "arn:aws:securityhub:eu-central-1::product/aws/inspector",
        "AwsAccountId": "047719614430",
        "RecordState": "ACTIVE",
        "Workflow": {"Status": "NEW"},
        "Severity": {"Label": severity},
        "CreatedAt": created,
        "UpdatedAt": created,
    }


def event(*findings):
    return {
        "source": "aws.securityhub",
        "detail-type": "Security Hub Findings - Imported",
        "region": "eu-central-1",
        "detail": {"findings": list(findings)},
    }


class RouterTests(unittest.TestCase):
    def setUp(self):
        self.env = patch.dict(os.environ, {
            "DELIVERY_TABLE_NAME": "finding-delivery",
            "FINDING_CUTOVER_AT": "2026-10-30T12:00:00Z",
            "SLACK_TOPIC_ARN": "arn:aws:sns:eu-central-1:047719614430:slack",
            "HIGH_TOPIC_ARN": "arn:aws:sns:eu-central-1:047719614430:opsgenie",
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.table = FakeTable()
        self.sns = FakeSns()

    def test_first_low_finding_goes_to_slack_only_once(self):
        new = event(finding())
        self.assertEqual(ROUTER.route_event(new, self.table, self.sns, now=100), {"slack": 1, "opsgenie": 0, "skipped": 0})
        self.assertEqual(ROUTER.route_event(new, self.table, self.sns, now=200), {"slack": 0, "opsgenie": 0, "skipped": 0})
        self.assertEqual([x["TopicArn"] for x in self.sns.published], [os.environ["SLACK_TOPIC_ARN"]])
        self.assertTrue(json.loads(self.sns.published[0]["Message"])["_dasmeta_first_delivery"])

    def test_later_high_severity_adds_opsgenie_without_repeating_slack(self):
        ROUTER.route_event(event(finding()), self.table, self.sns, now=100)
        high = event(finding(severity="HIGH"))
        self.assertEqual(ROUTER.route_event(high, self.table, self.sns, now=200), {"slack": 0, "opsgenie": 1, "skipped": 0})
        self.assertEqual(ROUTER.route_event(high, self.table, self.sns, now=300), {"slack": 0, "opsgenie": 0, "skipped": 0})
        self.assertEqual([x["TopicArn"] for x in self.sns.published], [os.environ["SLACK_TOPIC_ARN"], os.environ["HIGH_TOPIC_ARN"]])

    def test_critical_finding_goes_to_both_destinations_once(self):
        item = event(finding(severity="CRITICAL"))
        ROUTER.route_event(item, self.table, self.sns, now=100)
        ROUTER.route_event(item, self.table, self.sns, now=200)
        self.assertEqual(len(self.sns.published), 2)
        self.assertEqual(json.loads(self.sns.published[0]["Message"])["detail"]["findings"][0]["Id"], "finding-1")
        self.assertNotIn("_dasmeta_first_delivery", json.loads(self.sns.published[1]["Message"]))

    def test_pre_cutover_and_inactive_findings_do_not_publish(self):
        old = finding(created="2026-10-29T00:00:00Z")
        inactive = finding(identifier="finding-2")
        inactive["RecordState"] = "ARCHIVED"
        self.assertEqual(ROUTER.route_event(event(old, inactive), self.table, self.sns, now=100)["skipped"], 2)
        self.assertEqual(self.sns.published, [])

    def test_failed_opsgenie_publish_retries_without_repeating_slack(self):
        high = event(finding(severity="HIGH"))
        self.sns.fail_topic = os.environ["HIGH_TOPIC_ARN"]
        with self.assertRaisesRegex(RuntimeError, "SNS unavailable"):
            ROUTER.route_event(high, self.table, self.sns, now=100)
        self.sns.fail_topic = None
        self.assertEqual(ROUTER.route_event(high, self.table, self.sns, now=200), {"slack": 0, "opsgenie": 1, "skipped": 0})
        self.assertEqual([x["TopicArn"] for x in self.sns.published], [os.environ["SLACK_TOPIC_ARN"], os.environ["HIGH_TOPIC_ARN"]])

    def test_in_flight_claim_blocks_duplicate_until_lease_expires(self):
        item = finding()
        key = ROUTER._finding_key(item)
        self.table.items[key] = {"slack_state": "PENDING", "slack_lease": 145, "slack_token": "other-worker"}
        self.assertEqual(ROUTER.route_event(event(item), self.table, self.sns, now=100)["slack"], 0)
        self.assertEqual(ROUTER.route_event(event(item), self.table, self.sns, now=200)["slack"], 1)
        self.assertEqual(len(self.sns.published), 1)

    def test_multi_finding_event_publishes_one_finding_per_message(self):
        ROUTER.route_event(event(finding("one"), finding("two")), self.table, self.sns, now=100)
        ids = [json.loads(x["Message"])["detail"]["findings"][0]["Id"] for x in self.sns.published]
        self.assertEqual(ids, ["one", "two"])

    def test_resolution_is_sent_once_and_reopen_starts_new_episode(self):
        os.environ["OPSGENIE_API_MODE"] = "true"
        self.addCleanup(os.environ.pop, "OPSGENIE_API_MODE", None)
        active = finding(severity="HIGH")
        ROUTER.route_event(event(active), self.table, self.sns, now=100)
        resolved = {**active, "Workflow": {"Status": "RESOLVED"}, "UpdatedAt": "2026-11-01T00:00:00Z"}
        first = ROUTER.route_event(event(resolved), self.table, self.sns, now=200)
        self.assertEqual((first["resolved_slack"], first["closed_opsgenie"]), (1, 1))
        again = ROUTER.route_event(event(resolved), self.table, self.sns, now=300)
        self.assertEqual((again["resolved_slack"], again["closed_opsgenie"]), (0, 0))
        self.assertEqual(len(self.sns.published), 4)
        self.assertEqual(json.loads(self.sns.published[-1]["Message"])["_dasmeta_opsgenie_action"], "close")
        stale = {**active, "UpdatedAt": "2026-10-31T12:00:00Z"}
        self.assertEqual(ROUTER.route_event(event(stale), self.table, self.sns, now=400)["slack"], 0)
        reopened = {**active, "UpdatedAt": "2026-11-02T00:00:00Z"}
        result = ROUTER.route_event(event(reopened), self.table, self.sns, now=500)
        self.assertEqual((result["reopened"], result["slack"], result["opsgenie"]), (1, 1, 1))
        self.assertEqual(ROUTER.route_event(event(reopened), self.table, self.sns, now=600)["slack"], 0)

    def test_low_archive_sends_slack_only_and_old_endpoint_alert_is_not_closed(self):
        low = finding()
        ROUTER.route_event(event(low), self.table, self.sns, now=100)
        os.environ["OPSGENIE_API_MODE"] = "true"
        self.addCleanup(os.environ.pop, "OPSGENIE_API_MODE", None)
        archived = {**low, "RecordState": "ARCHIVED", "UpdatedAt": "2026-11-01T00:00:00Z"}
        result = ROUTER.route_event(event(archived), self.table, self.sns, now=200)
        self.assertEqual((result["resolved_slack"], result["closed_opsgenie"]), (1, 0))
        self.assertEqual(json.loads(self.sns.published[-1]["Message"])["_dasmeta_resolution_delivery"], "ARCHIVED")

    def test_preexisting_endpoint_alert_is_not_closed_by_api_mode(self):
        high = finding(severity="HIGH")
        ROUTER.route_event(event(high), self.table, self.sns, now=100)
        os.environ["OPSGENIE_API_MODE"] = "true"
        self.addCleanup(os.environ.pop, "OPSGENIE_API_MODE", None)
        resolved = {**high, "Workflow": {"Status": "RESOLVED"}, "UpdatedAt": "2026-11-01T00:00:00Z"}
        result = ROUTER.route_event(event(resolved), self.table, self.sns, now=200)
        self.assertEqual((result["resolved_slack"], result["closed_opsgenie"]), (1, 0))


if __name__ == "__main__":
    unittest.main()
