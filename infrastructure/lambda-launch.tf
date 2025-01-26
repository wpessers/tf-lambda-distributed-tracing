resource "aws_lambda_function" "launch" {
  function_name = "request-launch"
  role = ""

  filename = "../dist/lambdas.zip"
  handler = "lambdas/requestLaunchLambda.js"

  runtime = "nodejs18.x"
  architectures = [ "arm64" ]

  tracing_config {
    mode = "PassThrough"
  }
}
