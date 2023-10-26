import logging
import json
import os
import requests
import importlib
import sys
import types
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))

logger.info("log level: {}".format(LOGLEVEL))

def import_from_url(url):
    response = requests.get(url)
    if response.status_code == 200:
        module_name = url.split("/")[-1].split(".")[0]
        new_module = types.ModuleType(module_name)
        exec(response.text, new_module.__dict__)
        sys.modules[module_name] = new_module
        return new_module
    else:
        raise ImportError(f"Failed to fetch file from {url}, status code: {response.status_code}")

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
    file_url = "https://raw.githubusercontent.com/dasmeta/terraform-aws-monitoring/DMVP-2705/modules/cloudwatch-alarm-actions/modules/lambda-subscription/src/event_handler.py"
    module = import_from_url(file_url)
    region = os.environ['REGION']

    alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url = module.event_handler(event, context,region)

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
        return e
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
        return e
