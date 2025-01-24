resource "aws_lambda_function" "mission" {
  function_name = ""
  role = ""
  runtime = "nodejs18.x"

  tracing_config {
    mode = "PassThrough"
  }
}
