"""Deliver Security Hub finding lifecycle events to the Opsgenie Alert API."""

import hashlib
import json
import logging
import os
import time
import urllib.parse
import urllib.error
import urllib.request


LOG = logging.getLogger(__name__)
LOG.setLevel(logging.INFO)


def finding_alias(finding):
    identity = "|".join((finding["AwsAccountId"], finding["ProductArn"], finding["Id"]))
    return "securityhub-" + hashlib.sha256(identity.encode("utf-8")).hexdigest()


def alert_message(finding):
    parts = (
        os.environ.get("OPSGENIE_ALERT_PREFIX", "Security Hub"),
        finding.get("Severity", {}).get("Label", "UNKNOWN"),
        finding.get("ProductName", "Security Hub"),
        finding.get("Title", "Security finding"),
    )
    return " | ".join(parts)[:130]


def _request(method, path, payload=None):
    base = os.environ["OPSGENIE_API_URL"].rstrip("/")
    request = urllib.request.Request(
        base + path,
        data=json.dumps(payload).encode("utf-8") if payload is not None else None,
        headers={
            "Authorization": "GenieKey " + os.environ["OPSGENIE_API_KEY"],
            "Content-Type": "application/json",
        },
        method=method,
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=10) as response:
                body = json.loads(response.read())
                if response.status not in (200, 202):
                    raise RuntimeError(f"Opsgenie API returned HTTP {response.status}")
                return body
        except urllib.error.HTTPError as error:
            # Opsgenie may briefly serve stale API-key permissions after an
            # integration change. A persistent denial still fails the Lambda.
            if error.code != 403 or attempt == 3:
                raise
            time.sleep(0.5 * (attempt + 1))


def _wait_for_request(request_id):
    path = "/v2/alerts/requests/" + urllib.parse.quote(request_id, safe="")
    for attempt in range(8):
        try:
            result = _request("GET", path)
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            result = {}
        data = result.get("data", {})
        if "isSuccess" in data:
            if not data["isSuccess"]:
                raise RuntimeError("Opsgenie rejected alert action: " + data.get("status", "unknown"))
            return
        time.sleep(min(0.25 * (attempt + 1), 1))
    raise RuntimeError("Opsgenie alert action has no confirmed result")


def deliver(message):
    finding = message["detail"]["findings"][0]
    alias = finding_alias(finding)
    action = message.get("_dasmeta_opsgenie_action", "create")
    if action == "close":
        path = "/v2/alerts/" + urllib.parse.quote(alias, safe="") + "/close?identifierType=alias"
        result = _request("POST", path, {
            "user": "Security Hub finding router",
            "source": "AWS Security Hub",
            "note": "Finding resolved or archived in Security Hub",
        })
    elif action == "create":
        severity = finding.get("Severity", {}).get("Label", "UNKNOWN")
        result = _request("POST", "/v2/alerts", {
            "message": alert_message(finding),
            "alias": alias,
            "description": (finding.get("Description") or "Security Hub finding")[:15000],
            "priority": {"CRITICAL": "P1", "HIGH": "P2"}.get(severity, "P3"),
            "source": "AWS Security Hub",
            "details": {
                "AWS account": finding["AwsAccountId"],
                "Finding ID": finding["Id"],
                "Product ARN": finding["ProductArn"],
                "Record state": finding.get("RecordState", "UNKNOWN"),
            },
        })
    else:
        raise ValueError("Unknown Opsgenie action")
    request_id = result.get("requestId")
    if not request_id:
        raise RuntimeError("Opsgenie action returned no request ID")
    _wait_for_request(request_id)
    LOG.info("Opsgenie %s confirmed for finding alias %s", action, alias)


def lambda_handler(event, context):
    for record in event.get("Records", []):
        deliver(json.loads(record["Sns"]["Message"]))
