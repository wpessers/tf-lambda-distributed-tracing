module "test" {
  source = "./modules/otel-lambda-apigw"

  name              = "test"
  filename          = "../dist/lambdas.zip"
  handler           = "lambdas/requestLaunchLambda.handler"

  enabled_instrumentations = "http"

  extra_env_vars = {
    TEST = "test"
    TEST123 = "test123"
  }
}

resource "aws_lambda_permission" "apigw_invoke_test" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.test.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.launch.execution_arn}/*"
}

module "test2" {
  source = "./modules/otel-lambda-apigw"

  name              = "test2"
  filename          = "../dist/lambdas.zip"
  handler           = "lambdas/requestLaunchLambda.handler"
}

resource "aws_lambda_permission" "apigw_invoke_test2" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.test2.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.launch.execution_arn}/*"
}