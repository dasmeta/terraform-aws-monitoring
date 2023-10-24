import logging
import json
import os
import boto3
import base64
import requests

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))

logger.info("log level: {}".format(LOGLEVEL))

def create_jira_ticket(summary,description):
    # Jira API URL and authentication
    url = os.environ['JIRA_URL']
    username = os.environ['JIRA_USERNAME']
    password = os.environ['JIRA_PASSWORD']
    issue_data = {
        "fields": {
            "project": {"key": os.environ['JIRA_KEY']},
            "summary": summary,
            "description": description,
            "issuetype": {"name": "Task"},
            "labels": ["DevOps"]
        }
    }

    response = requests.post(url, json=issue_data, auth=(username, password))
    if response.status_code == 201:
        print("Issue created successfully. Issue key:", response.json()['key'])
    else:
        print("Failed to create issue. Status code:", response.status_code)
        print("Response content:", response.content)

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

def event_handler_for_metrics(metrics_body):

    for metrics_this in metrics_body:
        if  'MetricStat' in metrics_this:
            metric_stat = metrics_this["MetricStat"]

    metric = metric_stat["Metric"]
    metric_name = metric["MetricName"]
    metric_namespace = metric["Namespace"]

    dimension_string = ""
    MetricWidget = {}

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
    elif not len(metric["Dimensions"]):
        MetricWidget = {
            "width": 300,
            "height": 200,
            "metrics": [
                [
                    metric["Namespace"],
                    metric_name,
                    metric["MetricName"],
                    metric["Namespace"],
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
    return MetricWidget,dimension_string,metric_namespace,metric_name

def event_handler_for_expression(metrics_body):
    MetricWidget = {}
    metrics_widget = []
    metric_namespace = []
    metric_name = []

    for metrics_this in metrics_body:
        temp_metric = {}
        if  'Expression' in metrics_this:
            expression = metrics_this["Expression"]
        if  'MetricStat' in metrics_this:
            metric_stat = metrics_this["MetricStat"]
            metric = metric_stat["Metric"]
            temp_metric["Namespace"] = metric["Namespace"]
            temp_metric["MetricName"] = metric["MetricName"]
            temp_metric["id"] = metrics_this["Id"]
            temp_metric["Name"]  = str(metric["Dimensions"][0]["name"])
            temp_metric["Value"] = str(metric["Dimensions"][0]["value"])

            metric_name.append(temp_metric["MetricName"])
            metric_namespace.append(temp_metric["Namespace"])
            metrics_widget.append(temp_metric)
    metrics = []
    for item in metrics_widget:
        temp = []
        temp.append( item["Namespace"])
        temp.append( item["MetricName"])
        temp.append( item["Name"])
        temp.append( item["Value"])
        temp.append( {'id': item["id"]})

        print(temp)
        metrics.append(temp)

    metrics.append([{"expression" : expression}])


    MetricWidget = {
        "width": 600,
        "height": 395,
        "metrics": metrics,
        "period": 300,
        "view": "timeSeries"
    }
    return MetricWidget,expression,metric_namespace,metric_name

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

        if os.environ['CREATE_JIRA_TICKET']:
            all_data = items[0]["facts"]
            description = "Alarm Description: "
            description += f"\n{aws_alarmdescription}"
            description += f"\n h2. Details\n"
            description += f"\n".join([f"{item['title']}: {item['value']}" for item in all_data])
            description += f"\nURL: {url}"
            print("Create jira ticket")
            create_jira_ticket(subject,description)

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
    """send message via teams"""

    print("Event",event)
    print("Context",context)
    teams_webhook_url = os.environ['WEBHOOK_URL']
    url = "https://" + os.environ['REGION'] + ".console.aws.amazon.com/cloudwatch/home?region=" + \
        os.environ['REGION'] + "#alarmsV2:?~(alarmStateFilter~'ALARM)"
    # url = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#alarmsV2:?~(alarmStateFilter~%27ALARM)"

    logger.debug("Event: {}".format(event))
    message = str(event['Records'][0]['Sns']['Message'])
    subject = guess_subject(event)
    logger.debug("Event:" + str(event))
    logger.debug("Message: " + str(subject))
    logger.debug("Message: " + str(message))

    # Json handle and cut info
    json_body = json.loads(event["Records"][0]["Sns"]["Message"])
    # json_body = event["Records"][0]["Sns"]["Message"] #TODO: can be removed. This was used to debug lambda on fly
    trigger_body = json_body["Trigger"]
    aws_account = json_body["AWSAccountId"]
    aws_alarmdescription = json_body["AlarmDescription"]
    dimension_string = ""

    if "Metrics" in trigger_body:
        metrics_body = trigger_body["Metrics"]
        logger.debug("> Alarm Metrics Body Value", metrics_body)
        print("metrics_body: ",metrics_body)
        # processing one single metric
        # TODO: we need to manage multiple metrics processing
        # for metrics_this in metrics_body:
        #     try:
        #         metric_stat = metrics_this["MetricStat"]

        #     except KeyError:
        #         logger.debug("MetricStat is missing in this metric block")
        for metric_this in metrics_body:
            if metric_this["ReturnData"] == True:
                if "Expression" in metric_this:
                    MetricWidget,dimension_string,metric_namespace,metric_name = event_handler_for_expression(metrics_body)
                    alert_type = "Expression"
                else:
                    alert_type = "Metric"
                    MetricWidget,dimension_string,metric_namespace,metric_name = event_handler_for_metrics(metrics_body)

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

    payload_data = payload(alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url)

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
