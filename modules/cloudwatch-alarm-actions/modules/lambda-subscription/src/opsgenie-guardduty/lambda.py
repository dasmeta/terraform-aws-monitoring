import json
import logging
import os
import time
import urllib.error
import urllib.parse
import urllib.request


LOG = logging.getLogger(__name__)
LOG.setLevel(os.getenv("LOG_LEVEL", "INFO"))

DEFAULT_MAX_ATTEMPTS = 8
DEFAULT_RETRY_DELAY_SECONDS = 2


def build_description(event):
    detail = event.get("detail", {})
    service = detail.get("service", {})
    finding_id = detail.get("id", "unknown")
    region = detail.get("region") or event.get("region", "unknown")
    finding_link = build_finding_link(
        region,
        finding_id,
        partition=detail.get("partition", "aws"),
    )

    lines = [
        f"GuardDuty finding: {detail.get('type', 'unknown')}",
        f"Title: {detail.get('title', 'unknown')}",
        f"Severity score: {detail.get('severity', 'unknown')}",
        f"AWS account: {detail.get('accountId') or event.get('account', 'unknown')}",
        f"Region: {region}",
        f"Resource: {resource_summary(detail.get('resource', {}))}",
    ]

    remote_ip = first_remote_ip(service.get("action", {}))
    if remote_ip:
        lines.append(f"Remote IP: {remote_ip}")

    if service.get("eventFirstSeen"):
        lines.append(f"First seen: {service['eventFirstSeen']}")
    if service.get("eventLastSeen"):
        lines.append(f"Last seen: {service['eventLastSeen']}")
    if service.get("count") is not None:
        lines.append(f"Event count: {service['count']}")

    lines.extend(
        [
            f"Finding ID: {finding_id}",
            "",
            "Finding link:",
            finding_link,
            "",
            "Description:",
            detail.get("description", "No GuardDuty description was provided."),
            "",
            (
                "Action: Open the finding link, review the affected resource and AWS "
                "remediation guidance, then acknowledge only after the finding is "
                "resolved, archived, or confirmed as expected."
            ),
        ]
    )

    return "\n".join(lines)


def build_finding_link(region, finding_id, partition="aws"):
    encoded_region = urllib.parse.quote(str(region), safe="")
    encoded_finding_id = urllib.parse.quote(str(finding_id), safe="")
    console_domain = {
        "aws-cn": "console.amazonaws.cn",
        "aws-us-gov": "console.amazonaws-us-gov.com",
    }.get(partition, "console.aws.amazon.com")
    return (
        f"https://{console_domain}/guardduty/home?region={encoded_region}"
        f"#/findings?search=id%3D{encoded_finding_id}"
    )


def resource_summary(resource):
    resource_type = resource.get("resourceType", "unknown")

    instance = resource.get("instanceDetails", {}).get("instanceId")
    if instance:
        return f"{resource_type} / {instance}"

    rds_user = resource.get("rdsDbUserDetails", {})
    rds_user_parts = []
    if rds_user.get("database"):
        rds_user_parts.append(f"database {rds_user['database']}")
    if rds_user.get("user"):
        rds_user_parts.append(f"user {rds_user['user']}")

    rds = resource.get("rdsDbInstanceDetails", {}).get("dbInstanceIdentifier")
    if rds:
        suffix = f" / {' / '.join(rds_user_parts)}" if rds_user_parts else ""
        return f"{resource_type} / {rds}{suffix}"

    access_key = resource.get("accessKeyDetails", {}).get("accessKeyId")
    if access_key:
        principal = resource.get("accessKeyDetails", {}).get("principalId")
        if principal:
            return f"{resource_type} / {access_key} / {principal}"
        return f"{resource_type} / {access_key}"

    buckets = resource.get("s3BucketDetails") or []
    bucket_names = [bucket.get("name") for bucket in buckets if bucket.get("name")]
    if bucket_names:
        return f"{resource_type} / {', '.join(bucket_names)}"

    volumes = []
    ebs_volumes = resource.get("ebsVolumeDetails", {})
    for volume_group in ("scannedVolumeDetails", "skippedVolumeDetails"):
        for volume in ebs_volumes.get(volume_group, []):
            volume_arn = volume.get("volumeArn")
            if volume_arn and volume_arn not in volumes:
                volumes.append(volume_arn)
    if volumes:
        return f"{resource_type} / {', '.join(volumes)}"

    if rds_user_parts:
        return f"{resource_type} / {' / '.join(rds_user_parts)}"

    for details_key, identifier_keys in (
        ("ecsClusterDetails", ("name", "arn")),
        ("eksClusterDetails", ("name", "arn")),
        ("lambdaDetails", ("functionName", "functionArn")),
        ("containerDetails", ("name", "id")),
        ("ec2ImageDetails", ("imageArn", "imageId")),
        ("ebsSnapshotDetails", ("snapshotArn", "snapshotId")),
        ("recoveryPointDetails", ("recoveryPointArn",)),
        ("bedrockGuardrailDetails", ("guardrailArn", "guardrailId")),
        ("rdsLimitlessDbDetails", ("dbShardGroupIdentifier", "dbClusterIdentifier")),
    ):
        identifier = first_present(resource.get(details_key, {}), identifier_keys)
        if identifier:
            return f"{resource_type} / {identifier}"

    workload = resource.get("kubernetesDetails", {}).get(
        "kubernetesWorkloadDetails", {}
    )
    workload_name = workload.get("name")
    if workload_name:
        namespace = workload.get("namespace")
        identifier = f"{namespace}/{workload_name}" if namespace else workload_name
        return f"{resource_type} / {identifier}"

    # ResourceV2 provides stable top-level identifiers for all supported resources.
    identifier = first_present(resource, ("name", "uid"))
    if identifier:
        return f"{resource_type} / {identifier}"

    return resource_type


def first_present(value, keys):
    if not isinstance(value, dict):
        return None
    for key in keys:
        if value.get(key):
            return value[key]
    return None


def first_remote_ip(value):
    if isinstance(value, dict):
        remote_details = value.get("remoteIpDetails")
        if isinstance(remote_details, dict):
            remote_ip = remote_details.get("ipAddressV4") or remote_details.get(
                "ipAddressV6"
            )
            if remote_ip:
                return remote_ip

        for key, nested in value.items():
            if key == "localIpDetails":
                continue
            found = first_remote_ip(nested)
            if found:
                return found
    elif isinstance(value, list):
        for nested in value:
            found = first_remote_ip(nested)
            if found:
                return found
    return None


def handler(
    event,
    context,
    request_func=None,
    sleep_func=None,
    max_attempts=None,
):
    request_func = request_func or opsgenie_request
    sleep_func = sleep_func or time.sleep
    max_attempts = max_attempts or int(
        os.getenv("OPSGENIE_ALERT_SEARCH_RETRIES", DEFAULT_MAX_ATTEMPTS)
    )

    result = {"updated": 0, "ignored": 0, "failed": 0}

    for message in guardduty_messages(event):
        alias = message.get("id")
        if not alias:
            LOG.warning("GuardDuty event is missing EventBridge id; cannot match Opsgenie alias")
            result["failed"] += 1
            continue

        description = build_description(message)
        update_result = update_alert_description_by_alias(
            alias,
            description,
            request_func=request_func,
            sleep_func=sleep_func,
            max_attempts=max_attempts,
        )

        if update_result["updated"]:
            result["updated"] += 1
        else:
            result["failed"] += 1
            LOG.warning(
                "Failed to update Opsgenie alert description for alias %s after %s attempts",
                alias,
                update_result["attempts"],
            )

    result["ignored"] = count_ignored_records(event)
    if result["failed"]:
        raise RuntimeError(
            f"Failed to enrich {result['failed']} GuardDuty alert(s) in Opsgenie"
        )
    return result


def guardduty_messages(event):
    if is_guardduty_event(event):
        yield event
        return

    for record in event.get("Records", []):
        message = parse_sns_message(record)
        if is_guardduty_event(message):
            yield message


def count_ignored_records(event):
    records = event.get("Records")
    if not records:
        return 0 if is_guardduty_event(event) else 1

    ignored = 0
    for record in records:
        if not is_guardduty_event(parse_sns_message(record)):
            ignored += 1
    return ignored


def parse_sns_message(record):
    raw_message = record.get("Sns", {}).get("Message")
    if not raw_message:
        return {}
    try:
        return json.loads(raw_message)
    except json.JSONDecodeError:
        LOG.warning("Ignoring SNS record with non-JSON message")
        return {}


def is_guardduty_event(message):
    return (
        isinstance(message, dict)
        and message.get("source") == "aws.guardduty"
        and message.get("detail-type") == "GuardDuty Finding"
    )


def update_alert_description_by_alias(
    alias,
    description,
    request_func=None,
    sleep_func=None,
    max_attempts=None,
):
    request_func = request_func or opsgenie_request
    sleep_func = sleep_func or time.sleep
    max_attempts = max_attempts or int(
        os.getenv("OPSGENIE_ALERT_SEARCH_RETRIES", DEFAULT_MAX_ATTEMPTS)
    )
    retry_delay = float(
        os.getenv("OPSGENIE_ALERT_SEARCH_DELAY_SECONDS", DEFAULT_RETRY_DELAY_SECONDS)
    )
    alert_path = f"/v2/alerts/{urllib.parse.quote(alias, safe='')}?identifierType=alias"
    description_path = (
        f"/v2/alerts/{urllib.parse.quote(alias, safe='')}/description"
        "?identifierType=alias"
    )
    payload = {"description": description}

    for attempt in range(1, max_attempts + 1):
        status_code, response = request_func("GET", alert_path)
        if status_code == 200:
            update_status, update_response = request_func(
                "PUT",
                description_path,
                payload=payload,
            )
            if update_status in (200, 202):
                LOG.info("Updated Opsgenie alert description for alias %s", alias)
                return {
                    "updated": True,
                    "attempts": attempt,
                    "response": update_response,
                }

            LOG.warning(
                "Opsgenie alert description update failed for alias %s with HTTP %s: %s",
                alias,
                update_status,
                update_response,
            )
            return {
                "updated": False,
                "attempts": attempt,
                "response": update_response,
            }

        if status_code == 404 and attempt < max_attempts:
            LOG.info(
                "Opsgenie alert alias %s not found yet; retrying update attempt %s/%s",
                alias,
                attempt + 1,
                max_attempts,
            )
            sleep_func(retry_delay)
            continue

        LOG.warning(
            "Opsgenie alert lookup failed for alias %s with HTTP %s: %s",
            alias,
            status_code,
            response,
        )
        return {"updated": False, "attempts": attempt, "response": response}

    return {"updated": False, "attempts": max_attempts, "response": None}


def opsgenie_request(method, path, payload=None, api_url=None, api_key=None):
    api_url = (api_url or os.getenv("OPSGENIE_API_URL") or "https://api.opsgenie.com").rstrip("/")
    api_key = api_key or os.getenv("OPSGENIE_API_KEY")
    if not api_key:
        raise RuntimeError("OPSGENIE_API_KEY is required")

    body = None
    if payload is not None:
        body = json.dumps(payload).encode("utf-8")

    request = urllib.request.Request(
        f"{api_url}{path}",
        data=body,
        method=method,
        headers={
            "Accept": "application/json",
            "Authorization": f"GenieKey {api_key}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status, parse_response_body(response.read())
    except urllib.error.HTTPError as error:
        return error.code, parse_response_body(error.read())


def parse_response_body(raw_body):
    if not raw_body:
        return {}
    try:
        return json.loads(raw_body.decode("utf-8"))
    except json.JSONDecodeError:
        return {"body": raw_body.decode("utf-8", errors="replace")}
