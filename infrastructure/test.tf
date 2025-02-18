module "test" {
  source = "./modules/otel-lambda-apigw"

  name              = "test"
  filename          = "../dist/lambdas.zip"
  handler           = "lambdas/requestLaunchLambda.handler"
  api_execution_arn = aws_api_gateway_rest_api.launch.execution_arn

  extra_env_vars = {
    TEST : "test"
    TEST123 : "test123"
  }
}
