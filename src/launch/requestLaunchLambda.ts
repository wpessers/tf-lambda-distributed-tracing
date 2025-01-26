import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import process from 'process';

import LaunchRequest = Components.Schemas.LaunchRequest;
import LaunchResponse = Components.Schemas.LaunchResponse;
import ControlMissionResponse = Components.Schemas.ControlMissionResponse;

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    console.log("Lambda invoked")
    const requestBody = event?.body;

    if (!requestBody) {
        throw Error("Bad Request")
    }

    const { rocketName, destination } = JSON.parse(requestBody) as LaunchRequest;

    const missionControlHostname = process.env['MISSION_CONTROL_HOSTNAME']
    const missionResponse = await fetch(`https://${missionControlHostname}/test/mission/${rocketName}`, {
        method: 'GET'
    })
    const mission: ControlMissionResponse = await missionResponse.json()
    const status = mission.progress > 0 ? 'UNDERWAY' : 'LAUNCHING'

    return {
        statusCode: 200,
        body: JSON.stringify({
            rocketName,
            destination,
            status
        } as LaunchResponse)
    }
}
