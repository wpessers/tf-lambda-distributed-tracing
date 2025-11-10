module "control_mission" {
  source = "./modules/otel-lambda"

  name     = "control-mission"
  filename = "../dist/lambdas.zip"
  handler  = "lambdas/controlMissionLambda.handler"

  enabled_instrumentations = "http,undici"

  instrumentation_layer_arn = aws_lambda_layer_version.otel_layer.arn
  #   instrumentation_layer_arn = "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-nodejs-0_13_0:1"
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

  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [aws_sqs_queue.launch_queue.arn]
  }
}

resource "aws_iam_role_policy" "control_mission_role_policy" {
  name   = "control-mission-lambda-policy"
  policy = data.aws_iam_policy_document.control_mission_policy.json
  role   = module.control_mission.execution_role_id
}

resource "aws_lambda_event_source_mapping" "control_mission_launch_queue_mapping" {
  event_source_arn = aws_sqs_queue.launch_queue.arn
  function_name    = module.control_mission.function_arn
  batch_size       = 10
}
