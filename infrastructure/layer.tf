resource "aws_lambda_layer_version" "python_layer" {
  layer_name               = "otel-python-layer-test"
  filename                 = "../opentelemetry-python-layer.zip"
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_layer_version" "collector_layer" {
  layer_name               = "otel-collector-layer-test"
  filename                 = "../opentelemetry-collector-layer-arm64.zip"
  compatible_runtimes      = ["python3.13"]
  compatible_architectures = ["arm64"]
}
