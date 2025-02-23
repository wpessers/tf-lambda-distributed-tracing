output "function_name" {
    value = aws_lambda_function.lambda_function.function_name
}

output "function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "execution_role_id" {
  value = aws_iam_role.execution_role.id
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.log_group.arn
}