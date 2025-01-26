resource "aws_api_gateway_rest_api" "mission" {
  name = "mission-rest-api"
  body = templatefile("../src/mission/openapi.json", {
    mission_control_lambda_arn = aws_lambda_function.control_mission.arn
  })
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "mission" {
  depends_on = [aws_api_gateway_rest_api.mission]

  rest_api_id = aws_api_gateway_rest_api.mission.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.mission.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}
