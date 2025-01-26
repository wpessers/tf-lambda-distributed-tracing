import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

import ControlMissionResponse = Components.Schemas.ControlMissionResponse;

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {

    console.log("Test")

    return {
        statusCode: 200,
        body: JSON.stringify({
            destination: "Mars",
            progress: 10,
        } as ControlMissionResponse)
    }
}