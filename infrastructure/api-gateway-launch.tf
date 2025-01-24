resource "aws_api_gateway_rest_api" "launch" {
  name = "launch-rest-api"
  body = templatefile("../src/launch/openapi.json", {
    request_launch_lambda_arn = aws_lambda_function.launch.arn
  })
  endpoint_configuration {
    types = [ "REGIONAL" ]
  }
}

resource "aws_api_gateway_deployment" "launch" {
  depends_on = [ aws_api_gateway_rest_api.launch ]

  rest_api_id = aws_api_gateway_rest_api.launch.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.launch.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
