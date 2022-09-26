import json
import http.client, urllib.parse
from os import environ

DEBUG = environ.get("DEBUG", 0)

def lambda_handler(event, context):
    print ("> Alarm Name:", json.loads(event["Records"][0]["Sns"]["Message"])["AlarmName"])
    print ("> Alarm Body:", json.dumps(json.loads(event["Records"][0]["Sns"]["Message"])))

    json_body = json.loads(event["Records"][0]["Sns"]["Message"])
    trigger_body = json_body["Trigger"]
    print ("> Alarm Trigger Body Value",trigger_body)
    dimension_string = ""
    metric_name = ""
    metric_namespace = ""

    if "Metrics" in trigger_body:
        metrics_body = trigger_body["Metrics"]

        print ("> Alarm Metrics Body Value",metrics_body)
        metric_stat = metrics_body[0]["MetricStat"]
        metric = metric_stat["Metric"]
        metric_name = metric["MetricName"]
        metric_namespace = metric["Namespace"]

        for dimension_object in metric["Dimensions"]:
            dimension_string += dimension_object["name"] + "/" +  dimension_object["value"] + "/"
    else:
        for dimension_object in trigger_body["Dimensions"]:
            dimension_string += dimension_object["name"] + "/" +  dimension_object["value"] + "/"

        metric_name = trigger_body["MetricName"]
        metric_namespace = trigger_body["Namespace"]

    dictionary = {
        "records":
        [
        {
        "source":"CloudWatch Alerts",
        "event_class":json_body["AlarmName"], # alarm name
        "resource":dimension_string, # dimension
        "node":json_body["AWSAccountId"],
        "metric_name":metric_name,
        "type":metric_namespace, # Namespace
        "severity":"4",
        "description":json_body["NewStateReason"],
        "additional_info":json.dumps(trigger_body)
        }
        ]
    }

    jsonString_dictionary = json.dumps(dictionary)

    print("> Matched json format",jsonString_dictionary)


    print(environ["SERVICENOW_DOMAIN"], environ["SERVICENOW_PATH"])

    connection = http.client.HTTPSConnection(environ["SERVICENOW_DOMAIN"], 443)
    connection.set_debuglevel(DEBUG)

    headers = {
        "content-type": "application/json",
        "Authorization": environ["SERVICENOW_AUTH"]
    }

    # params have to be mapped to ServiceNow event structure
    connection.request("POST", environ["SERVICENOW_PATH"], jsonString_dictionary, headers)

    response = connection.getresponse()

    print("> Response: ", response.status, response.reason)
    print("> Response Body: ", json.dumps(response.read().decode('utf-8')))
