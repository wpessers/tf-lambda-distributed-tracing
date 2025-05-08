module "request_launch" {
  source = "./modules/otel-lambda"

  name     = "request-launch"
  filename = "../dist/lambdas.zip"
  handler  = "lambdas/requestLaunchLambda.handler"

  enabled_instrumentations = "pino,undici"

  extra_env_vars = {
    MISSION_CONTROL_BASE_URL = aws_api_gateway_deployment.mission.invoke_url
  }

  # instrumentation_layer_arn = aws_lambda_layer_version.otel_layer.arn
  instrumentation_layer_arn = "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-nodejs-0_13_0:1"
}

data "aws_iam_policy_document" "request_launch_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${module.request_launch.log_group_arn}:*"]
  }

  statement {
    effect = "Allow"
    actions = ["sqs:SendMessage"]
    resources = [ aws_sqs_queue.launch_queue.arn ]
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
