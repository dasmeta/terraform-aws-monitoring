import logging
import json
import os

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


def lambda_handler(event, context):
    """send message via teams"""

    teams_webhook_url = os.environ['WEBHOOK_URL']

    logger.info("Event: " + str(event))
    message = str(event['Records'][0]['Sns']['Message'])
    subject = guess_subject(event)
    logger.info("Event:" + str(event))
    logger.info("Message: " + str(subject))
    logger.info("Message: " + str(message))

    payload = {
      "@context": "https://schema.org/extensions",
      "@type": "MessageCard",
      "title": subject,
      "text": message
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
