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

variable "api_execution_arn" {
  description = "Execution arn of the ApiGateway REST API resource that uses the lambda as a proxy integration"
  type        = string
}

variable "extra_env_vars" {
  description = "Custom environment variables to be made available to function code through the lambda runtime"
  type        = map(string)
  default     = {}
}
