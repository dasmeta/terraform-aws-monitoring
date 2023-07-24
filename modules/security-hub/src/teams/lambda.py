import logging
import json
import os
import boto3
import base64

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))

logger.info("log level: {}".format(LOGLEVEL))

def payload(account,resources,types,recommendation,description,id,resource_type):
    items = [
            {
                "type": "FactSet",
                "facts": [{
                    "title": "AccountId",
                    "value": account
                }, {
                    "title": "Types",
                    "value": str(resource_type)
                }, {
                    "title": "Description",
                    "value": description
                }, {
                    "title": "Id",
                    "value": id
                },]
            }
        ]
    if recommendation == "" :
        content = {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "title": "Security Hub Scan",
                    "version": "1.2",
                    "msteams": {
                        "width": "Full"
                    },
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": str(types),
                            "size": "Large",
                            "weight": "Bolder",
                            "style": "heading"
                        },
                        {
                            "type": "Container",
                            "items": items
                        },
                        {
                            "type": "ActionSet",
                            "actions": [
                                {
                                    "type": "Action.OpenUrl",
                                    "title": "Security Hub Url",
                                    "url": "https://eu-central-1.console.aws.amazon.com/securityhub/home?region=eu-central-1#/findings?search=WorkflowStatus=%5Coperator%5C%3AEQUALS%5C%3ANEW"
                                }
                            ]
                        }
                    ]
                }

    else :
        content = {
            "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
            "type": "AdaptiveCard",
            "title": "Security Hub Scan",
            "version": "1.2",
            "msteams": {
                "width": "Full"
            },
            "body": [
                {
                    "type": "TextBlock",
                    "text": str(types),
                    "size": "Large",
                    "weight": "Bolder",
                    "style": "heading"
                },
                {
                    "type": "Container",
                    "items": items
                },
                {
                    "type": "ActionSet",
                    "actions": [
                        {
                            "type": "Action.OpenUrl",
                            "title": recommendation["Text"],
                            "url": recommendation["Url"]
                        }
                    ]
                },
                {
                    "type": "ActionSet",
                    "actions": [
                        {
                            "type": "Action.OpenUrl",
                            "title": "Security Hub Url",
                            "url": "https://eu-central-1.console.aws.amazon.com/securityhub/home?region=eu-central-1#/findings?search=WorkflowStatus=%5Coperator%5C%3AEQUALS%5C%3ANEW"
                        }
                    ]
                }
            ]
        }

    payload = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": "contentUrl",
                "content": content

            }
        ]
    }
    return payload

def handler(event, context):
    """send message via teams"""

    print("Event",event)
    teams_webhook_url = os.environ['WEBHOOK_URL']

    logger.debug("Event: {}".format(event))

    id          =  event["detail"]["findings"][0]["Resources"][0]["Id"]
    types       = event["detail"]["findings"][0]["Types"]
    account     = event["account"]
    resources   = event["detail"]["findings"][0]["Resources"]
    resource_type  = event["detail"]["findings"][0]["Resources"][0]["Type"]
    description    =  event["detail"]["findings"][0]["Description"]
    recommendation = ""
    if "Recommendation" in event["detail"]["findings"][0]:
        recommendation = event["detail"]["findings"][0]["Remediation"]["Recommendation"]



    payload_data = payload(account,resources,types,recommendation,description,id,resource_type)

    headers = {'Content-Type': 'application/json'}
    method = 'POST'

    logger.debug("payload: >> {}".format(payload_data))

    print("Payload data: ",payload_data)
    req = Request(
        teams_webhook_url,
        json.dumps(payload_data).encode('utf-8'),
        headers, method=method
    )

    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted")
        print("Message posted status 200 OK")
        return {"status": "200 OK"}
    except HTTPError as e:
        logger.debug(e)
        logger.error("Request failed: %d %s", e.code, e.reason)
        print("Request failed: %d %s", e.code, e.reason)
        return e
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
        print("Server connection failed: %s", e.reason)
        return e
