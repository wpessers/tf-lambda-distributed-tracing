resource "aws_lambda_layer_version" "nodejs_layer" {
  layer_name               = "otel-nodejs-layer-test"
  filename                 = "../opentelemetry-nodejs-layer.zip"
  compatible_runtimes      = ["nodejs24.x"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_layer_version" "collector_layer" {
  layer_name               = "otel-collector-layer-test"
  filename                 = "../opentelemetry-collector-layer-arm64.zip"
  compatible_runtimes      = ["nodejs24.x"]
  compatible_architectures = ["arm64"]
}
