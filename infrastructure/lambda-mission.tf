module "control_mission" {
  source = "./modules/otel-lambda"

  name     = "control-mission"
  filename = "../dist/lambdas.zip"
  handler  = "lambdas/controlMissionLambda.handler"
}

resource "aws_lambda_permission" "apigw_invoke_control_mission_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.control_mission.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mission.execution_arn}/*"
}
