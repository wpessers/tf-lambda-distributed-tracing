
## About this project

This is a proof-of-concept project to show how to setup distributed tracing for AWS Lambdas, without using AWS X-Ray. We use opentelemetry for collecting and exporting traces instead.
For this specific example I've chosen to use grafana cloud (Tempo) to inspect the traces.

## Project setup

The project deploys 2 API Gateway REST API's, each with 1 endpoint that has a lambda proxy integration.
Together, the REST API's are meant to be a rocket launch system. The launch API is where we can make a request to launch a specific rocket, the mission control api is the one that exposes data about rockets that have been launched. When a new launch is requested, the launch system makes a call to the mission control API to check if a rocket can be launched.
The lambdas contain some dummy code to emulate this functionality.

### Build

`npm run build` will build the deployment package. This script will bundle code for both lambdas and create a zip file containing both of them, as well as the collector.yaml containing config for the otel collector.
To build one of the lambdas separately use either the `:launch` or the `:mission` suffix in the build command.

### Deployment

Terraform is used to deploy the infrastructure on AWS. The base url of the mission control API is dynamically loaded into an environment variable of the launch lambda.
To deploy to your own account make sure you set the aws credentials env vars like so:
```
export AWS_ACCESS_KEY_ID=<your_access_key_id>
export AWS_SECRET_ACCESS_KEY=<your_access_key_value>
export AWS_DEFAULT_REGION=<your_default_region>
```

##


For generating the auth header I use this command: `echo -n "<grafana user id>:<grafana api key>" | base64`

Disclaimer:
Other than a distributed tracing POC, at this time the repo is not meant for any other purposes. There's lots of things that can be improved upon fairly easily like adding a dedicated esbuild build script instead of individual npm scripts.