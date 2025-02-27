import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand, GetItemCommand, GetItemCommandInput, PutItemCommandInput } from '@aws-sdk/client-dynamodb';

import ControlMissionResponse = Components.Schemas.ControlMissionResponse;

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    const rocketName = event.pathParameters?.rocketName

    if (!rocketName) {
        throw Error('No rocket name specified')
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