import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

import LaunchRequest = Components.Schemas.LaunchRequest;
import LaunchResponse = Components.Schemas.LaunchResponse;

export const handler = async(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    const requestBody = event?.body;

    if (!requestBody) {
        throw Error("Bad Request")
    }

    const launchRequest: LaunchRequest = JSON.parse(requestBody);
    // Make call to mission control to check mission status and launch if necessary

    return {
        statusCode: 200,
        body: JSON.stringify({} as LaunchResponse)
    }
}

// POST /launch {  name: "", destination: ""  }