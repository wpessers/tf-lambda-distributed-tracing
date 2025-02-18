data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "execution_policy" {
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 1
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "execution_role_policy" {
  name   = "${var.name}-lambda-policy"
  policy = data.aws_iam_policy_document.execution_policy.json
  role   = aws_iam_role.execution_role.id
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.name
  role          = aws_iam_role.execution_role.arn

  filename         = var.filename
  handler          = var.handler
  source_code_hash = filebase64sha256(var.filename)

  runtime       = "nodejs22.x"
  architectures = ["arm64"]

  layers = [
    "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-collector-arm64-0_13_0:1",
    "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-nodejs-0_12_0:1"
  ]

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = merge({
      AWS_LAMBDA_EXEC_WRAPPER : "/opt/otel-handler"
      OTEL_TRACES_EXPORTER : "otlp"
      OTEL_METRICS_EXPORTER : "otlp"
      OTEL_LOG_LEVEL : "DEBUG"
      OTEL_TRACES_SAMPLER : "always_on"
      OPENTELEMETRY_COLLECTOR_CONFIG_FILE : "/var/task/collector.yaml"
      OTEL_LAMBDA_DISABLE_AWS_CONTEXT_PROPAGATION = true
    }, var.extra_env_vars)
  }

  timeout = 20
}

resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.api_execution_arn}/*"
}
