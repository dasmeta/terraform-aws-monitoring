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

def guess_subject(event):
    """
    try to guess a good message subject
    Messages from CloudWatch e.g. concerning ECS don't come with a subject.
    """

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

def event_handler(event, context,region):
    """send message via teams"""

    print("Event",event)
    print("Context",context)

    url = "https://" + region + ".console.aws.amazon.com/cloudwatch/home?region=" + \
        region + "#alarmsV2:?~(alarmStateFilter~'ALARM)t"

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
    cloudwatch = boto3.client('cloudwatch', region_name=region)
    response = cloudwatch.get_metric_widget_image(
        MetricWidget=json.dumps(MetricWidget))
    encoded_data = base64.b64encode(
        response["MetricWidgetImage"]).decode('utf-8')
    image = 'data:image/png;base64, {}'.format(encoded_data)

    return alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url
