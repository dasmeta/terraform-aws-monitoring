"""Regression coverage for grouped Inspector ECR image notifications."""

import importlib.util
import json
from pathlib import Path

import pytest


ROUTER_PATH = Path(__file__).resolve().parents[1] / "functions" / "finding_router.py"
SPEC = importlib.util.spec_from_file_location("finding_router", ROUTER_PATH)
router = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(router)


def finding(finding_id, *, digest="a" * 64, repository="sela-backend", account="515966492915", region="us-east-2", resource_id=None):
    if resource_id is None:
        resource_id = f"arn:aws:ecr:{region}:{account}:repository/{repository}/sha256:{digest}"
    return {
        "Id": finding_id,
        "AwsAccountId": account,
        "ProductArn": f"arn:aws:securityhub:{region}:{account}:product/aws/inspector",
        "ProductName": "Inspector",
        "Title": f"CVE test {finding_id}",
        "CreatedAt": "2026-11-03T09:30:00Z",
        "UpdatedAt": "2026-11-03T09:30:00Z",
        "RecordState": "ACTIVE",
        "Workflow": {"Status": "NEW"},
        "Compliance": {"Status": "FAILED"},
        "Severity": {"Label": "CRITICAL"},
        "Resources": [{"Type": "AwsEcrContainerImage", "Id": resource_id}],
    }


def test_cves_on_one_ecr_image_share_group():
    first = router._group_identity(finding("cve-a"))
    second = router._group_identity(finding("cve-b"))
    assert first["key"] == second["key"]
    assert "sela-backend" in first["label"]


@pytest.mark.parametrize(
    "change",
    [
        {"digest": "b" * 64},
        {"repository": "another-repository"},
        {"account": "111122223333"},
        {"region": "us-west-2"},
    ],
)
def test_distinct_ecr_remediation_targets_stay_separate(change):
    assert router._group_identity(finding("cve-a"))["key"] != router._group_identity(finding("cve-b", **change))["key"]


def test_missing_image_digest_keeps_per_finding_grouping():
    resource_id = "arn:aws:ecr:us-east-2:515966492915:repository/sela-backend"
    assert router._group_identity(finding("cve-a", resource_id=resource_id))["key"] != router._group_identity(finding("cve-b", resource_id=resource_id))["key"]


def test_other_products_keep_per_finding_ecr_grouping():
    first, second = finding("cve-a"), finding("cve-b")
    first["ProductName"] = second["ProductName"] = "Security Hub"
    assert router._group_identity(first)["key"] != router._group_identity(second)["key"]


def test_existing_inspector_ec2_grouping_is_preserved():
    first, second = finding("cve-a"), finding("cve-b")
    for item in (first, second):
        item["Resources"] = [{
            "Type": "AwsEc2Instance",
            "Id": "arn:aws:ec2:us-east-2:515966492915:instance/i-1234567890abcdef0",
            "Tags": {"karpenter.sh/nodepool": "on-demand", "eks:cluster-name": "eks-prod"},
            "Details": {"AwsEc2Instance": {"ImageId": "ami-1234567890abcdef0"}},
        }]
    assert router._group_identity(first)["key"] == router._group_identity(second)["key"]


def test_urgent_delivery_deduplicates_cves_on_one_image(monkeypatch):
    first, second = finding("cve-a"), finding("cve-b")
    by_key = {router._finding_key(item): item for item in (first, second)}
    published = set()

    class Table:
        def update_item(self, **_kwargs):
            pass

    def get_item(_table, key):
        item = by_key[key]
        return {
            "notification_updated_at": item["UpdatedAt"],
            "notification_state": "ACTIVE",
            "notification_payload": json.dumps({"group": router._group_identity(item)}),
        }

    def publish_once(_table, _sns, key, destination, *_args):
        identity = (key, destination)
        if identity in published:
            return False
        published.add(identity)
        return True

    monkeypatch.setenv("FINDING_CUTOVER_AT", "2026-11-03T08:30:00Z")
    monkeypatch.setenv("GROUPED_DELIVERY_MODE", "true")
    monkeypatch.setenv("HIGH_TOPIC_ARN", "test-high-topic")
    monkeypatch.setenv("SLACK_TOPIC_ARN", "test-slack-topic")
    monkeypatch.setenv("DELIVERY_TABLE_NAME", "test-table")
    monkeypatch.setattr(router, "_record_grouped", lambda *_args: True)
    monkeypatch.setattr(router, "_get_item", get_item)
    monkeypatch.setattr(router, "_publish_once", publish_once)
    event = {"source": "aws.securityhub", "detail-type": "Security Hub Findings - Imported", "detail": {"findings": [first, second]}}

    assert router.route_event(event, Table(), object(), now=1793698200) == {
        "recorded": 2,
        "urgent": 1,
        "urgent_slack": 1,
        "skipped": 0,
    }
