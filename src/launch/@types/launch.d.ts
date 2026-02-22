declare namespace Components {
    namespace Schemas {
        export interface LaunchRequest {
            rocketName: string;
            destination: string;
        }
        export interface LaunchResponse {
            rocketName: string;
            destination: string;
            status: string;
        }
    }
}
declare namespace Paths {
    namespace RequestLaunch {
        export type RequestBody = Components.Schemas.LaunchRequest;
        namespace Responses {
            export type $200 = Components.Schemas.LaunchResponse;
        }
    }
}
