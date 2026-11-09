"""Resolve displayed ECR environments from a fresh, complete pod inventory."""

import json
import logging
import os
import re
from datetime import datetime, timezone

import boto3
from botocore.config import Config


LOG = logging.getLogger(__name__)
ECR_RESOURCE = re.compile(
    r"arn:(?:aws|aws-us-gov|aws-cn):ecr:([a-z0-9-]+):([0-9]{12}):repository/(.+)/sha256:([a-fA-F0-9]{64})$"
)


def load_inventory(s3=None, now=None):
    """Return None when disabled, or a validated snapshot state when enabled."""
    raw = os.environ.get("DEPLOYMENT_INVENTORY_CONFIG", "")
    if not raw:
        return None
    try:
        config = json.loads(raw)
        client = s3 or boto3.client("s3", config=Config(
            connect_timeout=2, read_timeout=2, retries={"total_max_attempts": 2}))
        body = client.get_object(Bucket=config["bucket"], Key=config["key"])["Body"].read(2_000_001)
        if len(body) > 2_000_000:
            raise ValueError("inventory exceeds 2 MB")
        snapshot = json.loads(body)
        observed = datetime.fromisoformat(snapshot["observed_at"].replace("Z", "+00:00"))
        current = now or datetime.now(timezone.utc)
        if observed.tzinfo is None or not 0 <= (current - observed).total_seconds() <= config["max_age_seconds"]:
            raise ValueError("inventory is stale or future-dated")
        if not config["required_clusters"] or set(snapshot["clusters"]) != set(config["required_clusters"]):
            raise ValueError("inventory cluster coverage is incomplete")
        images = {}
        for item in snapshot["images"]:
            digest = item["digest"].lower()
            if not re.fullmatch(r"sha256:[a-f0-9]{64}", digest):
                raise ValueError("invalid image digest")
            if not re.fullmatch(r"[0-9]{12}", item["account"]):
                raise ValueError("invalid image account")
            if not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,62}", item["environment"]):
                raise ValueError("invalid environment")
            key = (item["region"], item["account"], item["repository"], digest)
            images.setdefault(key, set()).add(item["environment"])
        return {"valid": True, "observed_at": observed, "max_age_seconds": config["max_age_seconds"], "images": images}
    except Exception as error:
        LOG.warning("Deployment inventory unavailable: %s", type(error).__name__)
        return {"valid": False}


def displayed_environment(records, inventory, now=None):
    """Use only a fresh complete inventory; absence is meaningful only then."""
    if inventory is None:
        return None
    current = now or datetime.now(timezone.utc)
    if not inventory.get("valid") or (current - inventory["observed_at"]).total_seconds() > inventory["max_age_seconds"]:
        return "Unverified"
    environments = set()
    seen_image = False
    for record in records:
        for resource in record.get("resource_ids", [record.get("resource", "")]):
            match = ECR_RESOURCE.fullmatch(resource)
            if not match:
                continue
            seen_image = True
            region, account, repository, digest = match.groups()
            environments.update(inventory["images"].get((region, account, repository, "sha256:" + digest.lower()), ()))
    if not seen_image:
        return "Unverified"
    return ", ".join(sorted(environments)) if environments else "No running workload found"
