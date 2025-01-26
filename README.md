This repo is a work in progress. The aim is to setup aws lambda distributed tracing, without having to use AWS's X-Ray. Instead using an external system like Grafana to inspect traces.
The code in this repo is a very barebones implementation of 2 lambda functions, simply to test distributed tracing throughout a system consisting of 2 different api gateway api's.
Each with only 1 endpoint that has a lambda proxy integration.


For generating the auth header I use this command: `echo -n "<grafana user id>:<grafana api key>" | base64`

Disclaimer:
Other than that, at this time the repo is not meant for any other purposes. There's lots of things that can be improved upon fairly easily like adding a dedicated esbuild build script instead of those horrendous looking npm scripts.
Also I didn't really adhere to strict coding standards / design principles for the dummy code used in the lambdas.
All that is out of scope for the aim of this repo though. We're simply trying to get a poc for distributed tracing over multiple lambdas.