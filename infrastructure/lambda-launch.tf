module "request_launch" {
  source = "./modules/otel-lambda"

  name     = "request-launch"
  filename = "../dist/lambdas.zip"
  handler  = "request_launch_lambda.handler"

  extra_env_vars = {
    MISSION_CONTROL_BASE_URL = aws_api_gateway_stage.mission_test.invoke_url
  }

  collector_layer_arn = aws_lambda_layer_version.collector_layer.arn
}

data "aws_iam_policy_document" "request_launch_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${module.request_launch.log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "request_launch_role_policy" {
  name   = "request-launch-lambda-policy"
  policy = data.aws_iam_policy_document.request_launch_policy.json
  role   = module.request_launch.execution_role_id
}

resource "aws_lambda_permission" "apigw_invoke_request_launch_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.request_launch.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.launch.execution_arn}/*"
}
