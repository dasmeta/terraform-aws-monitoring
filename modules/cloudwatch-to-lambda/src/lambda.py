import logging
import json
import os
import base64
import gzip
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

LOGLEVEL = os.environ.get('LOG_LEVEL', 'INFO').upper()
FALLBACK_SUBJECT = 'AWS Alerts'

logger = logging.getLogger()
logger.setLevel(getattr(logging, LOGLEVEL))

logger.info("log level: {}".format(LOGLEVEL))

def request_sender(uncompressed_data):
    url = os.environ['url']
    headers = {'Content-Type': 'application/json'}
    method = 'POST'

    req = Request(
        url,
        uncompressed_data,
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

def handler(event, context):
    data = event["awslogs"]["data"]
    print("event")
    print(event)
    print("data")
    print(data)
    try:
        # Decode the base64 data
        decoded_data = base64.b64decode(data)
        print("decoded_data")
        print(decoded_data)
        uncompressed_data = gzip.decompress(decoded_data)
        print("Uncompressed data: ")
        print(uncompressed_data)
        result = json.loads(uncompressed_data)
        print("Json Loads: ")
        print(result)
        request_sender(uncompressed_data)
    except base64.binascii.Error as e:
        print("Error decoding base64 data:", e)
