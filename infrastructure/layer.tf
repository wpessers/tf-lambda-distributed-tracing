resource "aws_lambda_layer_version" "javaagent_layer" {
  layer_name               = "otel-javaagent-layer-test"
  filename                 = "../opentelemetry-javaagent-layer.zip"
  compatible_runtimes      = ["java21"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_layer_version" "javawrapper_layer" {
  layer_name               = "otel-javawrapper-layer-test"
  filename                 = "../opentelemetry-javawrapper-layer.zip"
  compatible_runtimes      = ["java21"]
  compatible_architectures = ["arm64"]
}

resource "aws_lambda_layer_version" "collector_layer" {
  layer_name               = "otel-collector-layer-test"
  filename                 = "../opentelemetry-collector-layer-arm64.zip"
  compatible_runtimes      = ["java21"]
  compatible_architectures = ["arm64"]
}
