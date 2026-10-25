output "lambda_function_name" {
  value = aws_lambda_function.orders.function_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.orders.name
}

output "api_url" {
  description = "API Gateway 기본 엔드포인트"
  value       = aws_apigatewayv2_api.orders.api_endpoint
}
