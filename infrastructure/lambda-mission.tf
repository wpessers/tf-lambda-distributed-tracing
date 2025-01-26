data "aws_iam_policy_document" "control_mission_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "control_mission_role" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStrem", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.control_mission.arn}:*"]
  }
}

resource "aws_cloudwatch_log_group" "control_mission" {
  name              = "/aws/lambda/${aws_lambda_function.control_mission.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "control_mission" {
  name               = "control-mission-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.control_mission_assume_role.json
}

resource "aws_iam_role_policy" "control_mission" {
  name   = "control-mission-lambda-policy"
  policy = data.aws_iam_policy_document.control_mission_role.json
  role   = aws_iam_role.control_mission.id
}

resource "aws_lambda_function" "control_mission" {
  function_name = "control-mission"
  role          = aws_iam_role.control_mission.arn

  filename = "../dist/lambdas.zip"
  handler  = "lambdas/controlMissionLambda.js"

  runtime       = "nodejs18.x"
  architectures = ["arm64"]

  tracing_config {
    mode = "PassThrough"
  }
}

resource "aws_lambda_permission" "apigw_invoke_control_mission_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.control_mission.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mission.execution_arn}/*"
}
