import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

import InitiateLaunchRequest = Components.Schemas.InitiateLaunchRequest;
import InitiateLaunchResponse = Components.Schemas.InitiateLaunchResponse;


function getRequestBody(event: APIGatewayProxyEvent): InitiateLaunchRequest {
    const requestBody = event.body;

    if (!requestBody) {
        throw Error('Missing launch request body')
    }

    return JSON.parse(requestBody)
}

function mapToDomain(request: InitiateLaunchRequest):  {
    throw new Error('Function not implemented.');
}

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {

    mapToDomain(getRequestBody(event))

    return {
        statusCode: 200,
        body: JSON.stringify({
            rocketName,
            destination,
            status
        } as InitiateLaunchResponse)
    }
}

module.exports = { handler }
