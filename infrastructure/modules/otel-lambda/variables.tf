variable "name" {
  description = "Name of the OpenTelemetry-enabled ApiGateway proxy Lambda"
  type        = string
}

variable "handler" {
  description = "Entrypoint of the lambda function, should be a an exported handler method"
  type        = string
}

variable "filename" {
  description = "Location of the deployment package"
  type        = string
}

variable "extra_env_vars" {
  description = "Custom environment variables to be made available to function code through the lambda runtime"
  type        = map(string)
  default     = {}
}

variable "instrumentation_layer_arn" {
  type    = string
  default = "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-javaagent-arm64-0_18_0:1"
}

variable "collector_layer_arn" {
  type    = string
  default = "arn:aws:lambda:eu-central-1:184161586896:layer:opentelemetry-collector-arm64-0_19_0:1"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 512
}
