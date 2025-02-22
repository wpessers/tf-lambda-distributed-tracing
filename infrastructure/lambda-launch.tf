module "request_launch" {
  source = "./modules/otel-lambda"

  name     = "request-launch"
  filename = "../dist/lambdas.zip"
  handler  = "lambdas/requestLaunchLambda.handler"

  enabled_instrumentations = "http"

  extra_env_vars = {
    MISSION_CONTROL_BASE_URL = aws_api_gateway_deployment.mission.invoke_url
  }
}

resource "aws_lambda_permission" "apigw_invoke_request_launch_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.request_launch.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.launch.execution_arn}/*"
}
