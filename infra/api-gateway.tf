# 외부 HTTP 요청을 받는 API Gateway HTTP API
resource "aws_apigatewayv2_api" "orders" {
  name          = "${local.project}-http-api"
  protocol_type = "HTTP"
}

# API Gateway가 Lambda를 호출하도록 연결
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.orders.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.orders.invoke_arn
  payload_format_version = "2.0"
}

# GET /health 요청을 Lambda로 전달
resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.orders.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# POST /orders 요청을 Lambda로 전달
resource "aws_apigatewayv2_route" "create_order" {
  api_id    = aws_apigatewayv2_api.orders.id
  route_key = "POST /orders"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# 기본 스테이지: 배포 변경 사항을 자동 반영
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.orders.id
  name        = "$default"
  auto_deploy = true

  # 공개 학습용 API에 기본 요청 제한 설정
  default_route_settings {
    throttling_burst_limit = 5
    throttling_rate_limit  = 2
  }
}

# API Gateway에만 Lambda 호출 권한 부여
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.orders.execution_arn}/*/*"
}

# 주문 ID를 이용한 조회
resource "aws_apigatewayv2_route" "get_order" {
  api_id    = aws_apigatewayv2_api.orders.id
  route_key = "GET /orders/{orderId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# 주문 ID를 이용한 삭제
resource "aws_apigatewayv2_route" "delete_order" {
  api_id    = aws_apigatewayv2_api.orders.id
  route_key = "DELETE /orders/{orderId}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
