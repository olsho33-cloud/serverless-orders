# Lambda 서비스가 IAM 역할을 맡을 수 있도록 허용
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.project}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Lambda의 CloudWatch Logs 기록 권한
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 주문 테이블에만 PutItem 허용
data "aws_iam_policy_document" "dynamodb_write" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.orders.arn
    ]
  }
}

resource "aws_iam_role_policy" "dynamodb_write" {
  name   = "${local.project}-dynamodb-write"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_write.json
}
