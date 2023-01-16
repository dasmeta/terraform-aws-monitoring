import logging
import json
import os
import boto3
import datetime
import base64

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

LOGLEVEL = os.environ.get('LOGLEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))


def guess_subject(event):
    """
    try to guess a good message subject

    Messages from CloudWatch e.g. concerning ECS don't come with a subject.
    """

    # Just take the provided subject if there is one
    subject_from_sns = event['Records'][0]['Sns']['Subject']
    if str(subject_from_sns) != 'None' and len(subject_from_sns) > 0:
        logger.info("Message subject from SNS")
        return subject_from_sns
    else:
        logging.info(
            "Message subject not included in SNS, using fallback message subject")
        return FALLBACK_SUBJECT


def handler(event, context):
    """send message via teams"""

    teams_webhook_url = os.environ['WEBHOOK_URL']
    url = "https://" + os.environ['REGION'] + ".console.aws.amazon.com/cloudwatch/home?region=" + \
        os.environ['REGION'] + "#alarmsV2:?~(alarmStateFilter~%27ALARM)"
    # url = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#alarmsV2:?~(alarmStateFilter~%27ALARM)"

    logger.debug("Event: " + str(event))
    message = str(event['Records'][0]['Sns']['Message'])
    subject = guess_subject(event)
    logger.debug("Event:" + str(event))
    logger.debug("Message: " + str(subject))
    logger.debug("Message: " + str(message))

    # Json handle and cut info
    json_body = json.loads(event["Records"][0]["Sns"]["Message"])
    trigger_body = json_body["Trigger"]
    aws_account = json_body["AWSAccountId"]
    dimension_string = ""

    if "Metrics" in trigger_body:
        metrics_body = trigger_body["Metrics"]
        print("> Alarm Metrics Body Value", metrics_body)
        metric_stat = metrics_body[0]["MetricStat"]
        metric = metric_stat["Metric"]
        metric_name = metric["MetricName"]
        metric_namespace = metric["Namespace"]

        for dimension_object in metric["Dimensions"]:
            dimension_string += dimension_object["name"] + \
                "/" + dimension_object["value"] + "/"

        if len(metric["Dimensions"]) == 1:
            MetricWidget = {
                "width": 600,
                "height": 395,
                "metrics": [
                    [
                        metric["Namespace"],
                        metric_name,
                        metric["Dimensions"][0]["name"],
                        metric["Dimensions"][0]["value"],
                        {
                            "stat": "Average"
                        }
                    ]
                ],
                "period": 300,
                "view": "timeSeries"
            }
        else:
            MetricWidget = {
                "width": 600,
                "height": 395,
                "metrics": [
                    [
                        metric["Namespace"],
                        metric_name,
                        metric["Dimensions"][1]["name"],
                        metric["Dimensions"][1]["value"],
                        metric["Dimensions"][2]["name"],
                        metric["Dimensions"][2]["value"],
                        metric["Dimensions"][0]["name"],
                        metric["Dimensions"][0]["value"],
                        {
                            "stat": "Average"
                        }
                    ]
                ],
                "period": 300,
                "view": "timeSeries"
            }

    else:
        for dimension_object in trigger_body["Dimensions"]:
            dimension_string += dimension_object["name"] + \
                "/" + dimension_object["value"] + "/"

        metric_name = trigger_body["MetricName"]
        metric_namespace = trigger_body["Namespace"]
        MetricWidget = {
            "width": 600,
            "height": 395,
            "metrics": [
                [
                    metric_namespace,
                    metric_name,
                    trigger_body["Dimensions"][0]["name"],
                    trigger_body["Dimensions"][0]["value"],
                    {
                        "stat": "Minimum"
                    }
                ]
            ],
            "period": 60,
            "view": "timeSeries",
        }

    # Get Cloudwatch metric widget, encoded base64
    cloudwatch = boto3.client('cloudwatch', region_name=os.environ['REGION'])
    response = cloudwatch.get_metric_widget_image(
        MetricWidget=json.dumps(MetricWidget))
    encoded_data = base64.b64encode(
        response["MetricWidgetImage"]).decode('utf-8')
    image = 'data:image/png;base64, {}'.format(encoded_data)

    # Check subject and add smile)
    ok_check = "OK" in subject
    if ok_check:
        smile_subject = "✅ " + subject
    else:
        smile_subject = "❌ " + subject

    # Teams create AdaptiveCard and send
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
                            "items": [
                                {
                                    "type": "FactSet",
                                    "facts": [{
                                        "title": "AccountId",
                                        "value": aws_account
                                    }, {
                                        "title": "Dimensions",
                                        "value": dimension_string
                                    }, {
                                        "title": "Metic",
                                        "value": metric_namespace + "/" + metric_name
                                    }]
                                }
                            ]
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

    req = Request(
        teams_webhook_url,
        json.dumps(payload).encode('utf-8')
    )

    try:
        response = urlopen(req)
        response.read()
        logger.info("Message posted")
        return {"status": "200 OK"}
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
