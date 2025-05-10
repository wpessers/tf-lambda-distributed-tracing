import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { SendMessageCommand, SQSClient } from '@aws-sdk/client-sqs';
import process from 'process';

import LaunchRequest = Components.Schemas.LaunchRequest;
import LaunchResponse = Components.Schemas.LaunchResponse;

const sqsClient = new SQSClient({ region: 'eu-central-1' })

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    const requestBody = event.body;
    if (!requestBody) {
        throw Error('Missing launch request')
    }
    const { rocketName, destination } = JSON.parse(requestBody) as LaunchRequest;

    await sqsClient.send(
        new SendMessageCommand({
            QueueUrl: process.env['LAUNCH_QUEUE_URL'],
            MessageBody: JSON.stringify({ rocketName: rocketName })
        })
    )
    const status = 'LAUNCHING'

    return {
        statusCode: 200,
        body: JSON.stringify({
            rocketName,
            destination,
            status
        } as LaunchResponse)
    }
}

module.exports = { handler }