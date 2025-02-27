import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

import LaunchRequest = Components.Schemas.LaunchRequest;
import LaunchResponse = Components.Schemas.LaunchResponse;


function mapToDomain() {
    const requestBody = event.body;

    if (!requestBody) {
        throw Error('Missing launch request')
    }

    JSON.parse(requestBody) as LaunchRequest;
}

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    
    const { rocketName, destination } = JSON.parse(requestBody) as LaunchRequest;

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