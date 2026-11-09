import logging
import json
import os
import sys
import types
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from event_handler import event_handler

LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))

logger.info("log level: {}".format(LOGLEVEL))

def security_hub_message(raw_message):
    """Keep Security Hub Teams cards readable and below webhook payload limits."""
    try:
        event = json.loads(raw_message)
    except (TypeError, ValueError):
        return None
    if not isinstance(event, dict):
        return None
    digest = event.get("_dasmeta_group_digest")
    if isinstance(digest, dict):
        return (
            f"Security Hub digest: {digest.get('label', 'remediation group')}\n"
            f"Environment: {digest.get('environment') or 'Unverified'}\n"
            f"New or escalated: {digest.get('new_count', 0)}; active: {digest.get('active_count', 0)}\n"
            f"{digest.get('finding_url', '')}"
        )[:1500]
    if event.get("detail-type") != "Security Hub Findings - Imported":
        return None
    findings = event.get("detail", {}).get("findings") or []
    if not findings:
        return None
    finding = findings[0]
    group = event.get("_dasmeta_group") or {}
    resource = (finding.get("Resources") or [{}])[0].get("Id", "")
    severity = finding.get("Severity", {}).get("Label", "UNKNOWN")
    kind = "Urgent security finding" if event.get("_dasmeta_group_urgent") else "Security finding"
    region = event.get("region") or os.environ.get("REGION", "unknown")
    url = f"https://console.aws.amazon.com/securityhub/home?region={region}#/findings"
    return (
        f"{kind}: {severity} - {finding.get('Title', 'Finding')[:180]}\n"
        f"Remediation target: {group.get('label') or resource[:250]}\n"
        f"Security Hub: {url}"
    )[:1500]

def handle_notification(event):
    # Function to handle notification logic
    subject = event['Sns'].get('Subject') or FALLBACK_SUBJECT
    message = event['Sns'].get('Message') or ''
    message = security_hub_message(message) or message
    items = [
            {
                "type": "FactSet",
                "facts": [{
                    "title": "Message",
                    "value": message
                }]
            }
        ]
    payload = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": "contentUrl",
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "title": subject,
                    "version": "1.2",
                    "msteams": {
                        "width": "Full"
                    },
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": subject,
                            "size": "Large",
                            "weight": "Bolder",
                            "style": "heading"
                        },
                        {
                            "type": "Container",
                            "items": items
                        },
                    ]

                }
            }
        ]
    }
    return payload

def payload(alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url):
    if alert_type == "Expression":
        items = [
                    {
                        "type": "FactSet",
                        "facts": [{
                            "title": "AccountId",
                            "value": aws_account
                        }, {
                            "title": "Expression",
                            "value": dimension_string
                        },{
                            "title": "Metrics",
                            "value": str(metric_name)
                        },{
                            "title": "Namespaces",
                            "value": str(metric_namespace)
                        }]
                    }
                ]
        print("Items: ", items)
    else:
        items = [
                    {
                        "type": "FactSet",
                        "facts": [{
                            "title": "AccountId",
                            "value": aws_account
                        }, {
                            "title": "Dimensions",
                            "value": dimension_string
                        }, {
                            "title": "Metric",
                            "value": metric_namespace + "/" + metric_name
                        }]
                    }
                ]

    # Check subject and add smile)
    ok_check = "OK" in subject
    if ok_check:
        smile_subject = "✅ " + subject
    else:
        smile_subject = "❌ " + subject

    payload = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": "contentUrl",
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "title": subject,
                    "version": "1.2",
                    "msteams": {
                        "width": "Full"
                    },
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": smile_subject,
                            "size": "Large",
                            "weight": "Bolder",
                            "style": "heading"
                        },
                        {
                            "type": "Container",
                            "items": items
                        },
                        {
                            "type": "Image",
                            "url": image
                        },
                        {
                            "type": "ActionSet",
                            "actions": [
                                {
                                    "type": "Action.OpenUrl",
                                    "title": "See more",
                                    "url": url
                                }
                            ]
                        }
                    ]

                }
            }
        ]
    }
    return payload

def handler(event, context):
    region = os.environ['REGION']

    logger.debug("Event: ",event)
    if 'Records' in event:
        for record in event['Records']:
            if 'Sns' in record and record['Sns'].get('Type') == 'Notification':
                payload_data = handle_notification(record)
    else:
        alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url = event_handler(event, context,region)
        payload_data = payload(alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url)

    teams_webhook_url =os.environ['WEBHOOK_URL']
    headers = {'Content-Type': 'application/json'}
    method = 'POST'

    logger.debug("payload: >> {}".format(payload_data))

    req = Request(
        teams_webhook_url,
        json.dumps(payload_data).encode('utf-8'),
        headers, method=method
    )

    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted")
        return {"status": "200 OK"}
    except HTTPError as e:
        logger.debug(e)
        logger.error("Request failed: %d %s", e.code, e.reason)
        raise
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
        raise
