resource "aws_api_gateway_rest_api" "launch" {
  name = "launch-rest-api"
  body = templatefile("../src/launch/openapi.json", {
    request_launch_lambda_arn = module.request_launch.function_arn
  })
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "launch" {
  depends_on = [aws_api_gateway_rest_api.launch]

  rest_api_id = aws_api_gateway_rest_api.launch.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.launch.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "launch_test" {
  deployment_id = aws_api_gateway_deployment.launch.id
  rest_api_id = aws_api_gateway_rest_api.launch.id
  stage_name = "test"
}
