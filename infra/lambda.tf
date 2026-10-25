# 로컬 Python 코드를 ZIP 파일로 패키징
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../app/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda 로그 보존 기간 제한
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.project}-api"
  retention_in_days = 7
}

resource "aws_lambda_function" "orders" {
  function_name = "${local.project}-api"
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      ORDERS_TABLE = aws_dynamodb_table.orders.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy.dynamodb_write,
    aws_cloudwatch_log_group.lambda
  ]
}
