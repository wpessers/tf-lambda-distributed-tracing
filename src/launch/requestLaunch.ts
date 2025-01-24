import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

type LaunchRequest = {
    name: string,
    destination: string,
}

type LaunchResponse = {
    id: string,
    status: "LAUNCHING" | "LAUNCHED"
}

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