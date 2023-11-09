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

def handler(event, context):

    url = "https://4eb8-195-250-69-234.ngrok-free.app/aws"
    headers = {'Content-Type': 'application/json'}
    method = 'POST'

    print("lambda Request: ")
    req = Request(
        url,
        json.dumps(event).encode('utf-8'),
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
