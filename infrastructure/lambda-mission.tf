module "control_mission" {
  source = "./modules/otel-lambda"

  name     = "control-mission"
  filename = "../dist/lambdas.zip"
  handler  = "lambdas/controlMissionLambda.handler"

  enabled_instrumentations = ""
}

data "aws_iam_policy_document" "control_mission_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${module.control_mission.log_group_arn}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.mission.arn]
  }
}

resource "aws_iam_role_policy" "control_mission_role_policy" {
  name   = "control-mission-lambda-policy"
  policy = data.aws_iam_policy_document.control_mission_policy.json
  role   = module.control_mission.execution_role_id
}

resource "aws_lambda_permission" "apigw_invoke_control_mission_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.control_mission.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.mission.execution_arn}/*"
}
