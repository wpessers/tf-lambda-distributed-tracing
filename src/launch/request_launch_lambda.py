import json
import logging
import os
import urllib.request

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info("Incoming launch request")

    request_body = event.get("body")
    if not request_body:
        raise ValueError("Missing launch request")

    body = json.loads(request_body)
    rocket_name = body["rocketName"]
    destination = body["destination"]

    mission_control_base_url = os.environ["MISSION_CONTROL_BASE_URL"]
    req = urllib.request.Request(
        f"{mission_control_base_url}/mission/{rocket_name}", method="GET"
    )
    with urllib.request.urlopen(req) as response:
        mission = json.loads(response.read().decode())

    status = "UNDERWAY" if mission["progress"] > 0 else "LAUNCHING"

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "rocketName": rocket_name,
                "destination": destination,
                "status": status,
            }
        ),
    }
