resource "aws_lambda_layer_version" "otel_layer" {
    layer_name = "otel-nodejs-layer-test"
    filename = "../layer.zip"
    compatible_runtimes = [ "nodejs22.x" ]
    compatible_architectures = [ "arm64" ]
}
