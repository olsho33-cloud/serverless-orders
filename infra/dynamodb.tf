# 주문 데이터를 저장하는 DynamoDB 테이블
resource "aws_dynamodb_table" "orders" {
  name         = "${local.project}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  tags = {
    Project = local.project
  }
}
