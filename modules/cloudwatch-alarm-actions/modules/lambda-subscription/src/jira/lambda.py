import os
import requests
import sys
import types
from event_handler import event_handler

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

def handler(event, context):
    region = os.environ['REGION']
    alert_type,subject,aws_account,aws_alarmdescription,dimension_string,metric_namespace,metric_name,image,url = event_handler(event, context,region)

    if alert_type == "Expression":
        all_data =  [
            {
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
            }
        ]
    else:
        all_data =  [
            {
                "title": "AccountId",
                "value": aws_account
            }, {
                "title": "Dimensions",
                "value": dimension_string
            }, {
                "title": "Metric",
                "value": metric_namespace + "/" + metric_name
            }
        ]

    ok_check = "OK" in subject
    if not ok_check:
        description = f"\n{aws_alarmdescription}"
        description += f"\n h2. Details\n"
        description += f"\n".join([f"{item['title']}: {item['value']}" for item in all_data])
        description += f"\nURL: {url}"
        print("Create jira ticket")
        create_jira_ticket(subject,description)
