import json

import boto3


def handler(event, context):
    rocket_name = event["pathParameters"]["rocketName"]
    if not rocket_name:
        raise ValueError("No rocket name specified")

    client = boto3.client("dynamodb", region_name="eu-central-1")

    response = client.get_item(
        TableName="Mission", Key={"RocketName": {"S": rocket_name}}
    )

    if "Item" not in response:
        client.put_item(
            TableName="Mission",
            Item={
                "RocketName": {"S": rocket_name},
                "Destination": {"S": "Mars"},
                "Progress": {"N": "0"},
            },
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"destination": "Mars", "progress": 10}),
    }
