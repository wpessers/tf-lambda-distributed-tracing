declare namespace Components {
    namespace Schemas {
        export interface ControlMissionResponse {
            destination: string;
            progress: number;
        }
    }
}
declare namespace Paths {
    namespace ControlMission {
        namespace Parameters {
            export type NewLaunch = boolean;
            export type RocketName = string;
        }
        export interface PathParameters {
            rocketName: Parameters.RocketName;
        }
        export interface QueryParameters {
            newLaunch?: Parameters.NewLaunch;
        }
        namespace Responses {
            export type $200 = Components.Schemas.ControlMissionResponse;
        }
    }
}
