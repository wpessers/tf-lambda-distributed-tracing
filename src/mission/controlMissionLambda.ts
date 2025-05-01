import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand, GetItemCommand, GetItemCommandInput, PutItemCommandInput } from '@aws-sdk/client-dynamodb';

import ControlMissionResponse = Components.Schemas.ControlMissionResponse;

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    const rocketName = event.pathParameters!['rocketName']
    if (!rocketName) {
        throw Error('No rocket name specified')
    }

    const client = new DynamoDBClient({
        region: 'eu-central-1'
    })
    const input: GetItemCommandInput = {
        TableName: 'Mission',
        Key: {
            'RocketName': {
                'S': rocketName
            },
        },
    }
    const response = await client.send(new GetItemCommand(input))

    if (!response.Item) {
        const createInput: PutItemCommandInput = {
            TableName: 'Mission',
            Item: {
                'RocketName': {
                    'S': rocketName
                },
                'Destination': {
                    'S': 'Mars'
                },
                'Progress': {
                    'N': '0'
                }
            }
        }
        await client.send(new PutItemCommand(createInput))
    }

    return {
        statusCode: 200,
        body: JSON.stringify({
            destination: 'Mars',
            progress: 10,
        } as ControlMissionResponse)
    }
}

module.exports = { handler }