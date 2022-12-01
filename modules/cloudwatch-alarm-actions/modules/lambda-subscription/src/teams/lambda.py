import logging
import json
import os
import boto3
import datetime
import base64

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FALLBACK_SUBJECT = 'AWS Alerts'


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
        logging.info("Message subject not included in SNS, using fallback message subject")
        return FALLBACK_SUBJECT

def isResistent(region,subject):
    if region in subject:
        return True
    else:
        return False
        
def handler(event, context):
    """send message via teams"""

    teams_webhook_url = os.environ['WEBHOOK_URL']

    logger.info("Event: " + str(event))
    message = str(event['Records'][0]['Sns']['Message'])
    subject = guess_subject(event)
    logger.info("Event:" + str(event))
    logger.info("Message: " + str(subject))
    logger.info("Message: " + str(message))
    
    
    json_body = json.loads(event["Records"][0]["Sns"]["Message"])
    trigger_body = json_body["Trigger"]
    metrics_body = trigger_body["Metrics"]
    print ("> Alarm Metrics Body Value",metrics_body)
    metric_stat = metrics_body[0]["MetricStat"]
    metric = metric_stat["Metric"]
    metric_name = metric["MetricName"]
    metric_namespace = metric["Namespace"]
    aws_account = json_body["AWSAccountId"]
    dimension_string = ""
    dimension_name = metric["Dimensions"][0]["name"]
    dimension_value = metric["Dimensions"][0]["value"]
    
    for dimension_object in metric["Dimensions"]:
        dimension_string += dimension_object["name"] + "/" +  dimension_object["value"] + "/"
    
    url_frankfurt = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#alarmsV2:?~(alarmStateFilter~%27ALARM)"
    
    cloudwatch = boto3.client('cloudwatch', region_name='eu-central-1')
    print(metric["Dimensions"])
    print("dimension_name")
    print(dimension_name)
    print("dimension_value")
    print(dimension_value)
    print("MetricName")
    print(metric_name)
    print("Namespace")
    print(metric["Namespace"])
    
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

    print("MetricWidget")
    print(json.dumps(MetricWidget))


    response = cloudwatch.get_metric_widget_image(MetricWidget=json.dumps(MetricWidget))
    print(response["MetricWidgetImage"])    
    encoded_data = base64.b64encode(response["MetricWidgetImage"]).decode('utf-8')
    print("encoded_data")
    print(encoded_data)
    print("Image")
    image = 'data:image/png;base64, {}'.format(encoded_data)
    print(image)

    payload = {
       "type":"message",
       "attachments":[
          {
             "contentType":"application/vnd.microsoft.card.adaptive",
             "contentUrl":"contentUrl",
             "content":{
                "$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
                "type":"AdaptiveCard",
                "title": "❌" + " " + subject,
                "version":"1.2",
                "msteams": {
                    "width": "Full"
                },
                "body":[
                    {
                    "type": "TextBlock",
                    "text": "❌" + " " + subject,
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
                            "url": "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#alarmsV2:?~(alarmStateFilter~%27ALARM)"
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
        return { "status": "200 OK"}
    except HTTPError as e:
        logger.error("Request failed: %d %s", e.code, e.reason)
    except URLError as e:
        logger.error("Server connection failed: %s", e.reason)
