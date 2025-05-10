import { SQSEvent, SQSHandler, SQSRecord } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand, GetItemCommand, GetItemCommandInput, PutItemCommandInput } from '@aws-sdk/client-dynamodb';

const dynamoClient = new DynamoDBClient({
    region: 'eu-central-1'
})

const handler: SQSHandler = async (event: SQSEvent): Promise<void> => {
    for (const message of event.Records) {
        await processMessage(message)
    }
}

async function processMessage(message: SQSRecord) {
    const launch: { rocketName: string } = JSON.parse(message.body)
    if (!launch.rocketName) {
        throw Error('No rocket name specified')
    }

    const input: GetItemCommandInput = {
        TableName: 'Mission',
        Key: {
            'RocketName': {
                'S': launch.rocketName
            },
        },
    }
    const response = await dynamoClient.send(new GetItemCommand(input))
    if (!response.Item) {
        const createInput: PutItemCommandInput = {
            TableName: 'Mission',
            Item: {
                'RocketName': {
                    'S': launch.rocketName
                },
                'Destination': {
                    'S': 'Mars'
                },
                'Progress': {
                    'N': '0'
                }
            }
        }
        await dynamoClient.send(new PutItemCommand(createInput))

    }
}

module.exports = { handler }