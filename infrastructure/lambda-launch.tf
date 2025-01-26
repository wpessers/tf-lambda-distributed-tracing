data "aws_iam_policy_document" "request_launch_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "request_launch_role" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.request_launch.arn}:*"]
  }
}

resource "aws_cloudwatch_log_group" "request_launch" {
  name              = "/aws/lambda/${aws_lambda_function.request_launch.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "request_launch" {
  name               = "request-launch-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.request_launch_assume_role.json
}

resource "aws_iam_role_policy" "request_launch" {
  name   = "request-launch-lambda-policy"
  policy = data.aws_iam_policy_document.request_launch_role.json
  role   = aws_iam_role.request_launch.id
}

resource "aws_lambda_function" "request_launch" {
  function_name = "request-launch"
  role          = aws_iam_role.request_launch.arn

  filename         = "../dist/lambdas.zip"
  handler          = "lambdas/requestLaunchLambda.handler"
  source_code_hash = filebase64sha256("../dist/lambdas.zip")

  runtime       = "nodejs18.x"
  architectures = ["arm64"]

  layers = [
    "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-collector-arm64-0_11_0:1",
    "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-nodejs-0_11_0:1"
  ]

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER : "/opt/otel-handler"
      OPENTELEMETRY_COLLECTOR_CONFIG_URI : "/var/task/collector.yaml"
      OTEL_TRACES_SAMPLER : "always_on"
      MISSION_CONTROL_HOSTNAME : var.mission_control_hostname
    }
  }
}

resource "aws_lambda_permission" "apigw_invoke_request_launch_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_launch.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.launch.execution_arn}/*"
}
