import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import process from 'process';

import LaunchRequest = Components.Schemas.LaunchRequest;
import LaunchResponse = Components.Schemas.LaunchResponse;
import ControlMissionResponse = Components.Schemas.ControlMissionResponse;

const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    const requestBody = event.body;

    if (!requestBody) {
        throw Error('Missing launch request')
    }

    const { rocketName, destination } = JSON.parse(requestBody) as LaunchRequest;

    const missionControlBaseUrl = process.env['MISSION_CONTROL_BASE_URL']
    const missionResponse = await fetch(`${missionControlBaseUrl}test/mission/${rocketName}`, {
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

module.exports = { handler }