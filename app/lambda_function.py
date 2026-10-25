import json
from decimal import Decimal
import logging
import os
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def decimal_to_json(value):
    """DynamoDB Decimal을 JSON 직렬화 가능한 숫자로 변환한다."""
    if isinstance(value, Decimal):
        return int(value) if value == value.to_integral_value() else float(value)

    raise TypeError(f"Unsupported JSON type: {type(value).__name__}")


def response(status_code, body):
    """API Gateway HTTP API v2 응답 생성."""
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=decimal_to_json),
    }


def get_table():
    """DynamoDB 테이블 객체 반환."""
    table_name = os.environ.get("ORDERS_TABLE")

    if not table_name:
        return None

    import boto3
    return boto3.resource("dynamodb").Table(table_name)


def lambda_handler(event, context):
    """주문 생성·조회·삭제 API 진입점."""
    method = event.get("requestContext", {}).get("http", {}).get("method")
    path = event.get("rawPath", "")

    if method == "GET" and path == "/health":
        return response(200, {"status": "healthy"})

    # POST /orders
    if method == "POST" and path == "/orders":
        try:
            body = json.loads(event.get("body") or "{}")
        except (json.JSONDecodeError, TypeError):
            return response(400, {"error": "Invalid JSON"})

        if not isinstance(body, dict):
            return response(400, {"error": "JSON object required"})

        product = body.get("product")
        quantity = body.get("quantity")

        if (
            not isinstance(product, str)
            or not product.strip()
            or type(quantity) is not int
            or quantity <= 0
        ):
            return response(
                400,
                {"error": "product and positive integer quantity are required"},
            )

        order = {
            "orderId": str(uuid.uuid4()),
            "product": product.strip(),
            "quantity": quantity,
            "status": "CREATED",
        }

        try:
            table = get_table()
            if table:
                table.put_item(Item=order)
        except Exception:
            logger.exception("Failed to create order")
            return response(500, {"error": "Internal server error"})

        logger.info("Order created: %s", order["orderId"])
        return response(201, order)

    # GET /orders/{orderId}
    if method == "GET" and path.startswith("/orders/"):
        order_id = path.removeprefix("/orders/")

        if not order_id or "/" in order_id:
            return response(404, {"error": "Not Found"})

        try:
            table = get_table()

            if table is None:
                return response(503, {"error": "Database not configured"})

            result = table.get_item(Key={"orderId": order_id})
            order = result.get("Item")

            if not order:
                return response(404, {"error": "Order not found"})

            return response(200, order)

        except Exception:
            logger.exception("Failed to get order")
            return response(500, {"error": "Internal server error"})

    # DELETE /orders/{orderId}
    if method == "DELETE" and path.startswith("/orders/"):
        order_id = path.removeprefix("/orders/")

        if not order_id or "/" in order_id:
            return response(404, {"error": "Not Found"})

        try:
            table = get_table()

            if table is None:
                return response(503, {"error": "Database not configured"})

            # 조건부 삭제: 주문이 존재할 때만 삭제
            from botocore.exceptions import ClientError

            try:
                table.delete_item(
                    Key={"orderId": order_id},
                    ConditionExpression="attribute_exists(orderId)",
                )
            except ClientError as error:
                if error.response["Error"]["Code"] == "ConditionalCheckFailedException":
                    return response(404, {"error": "Order not found"})
                raise

            logger.info("Order deleted: %s", order_id)
            return response(200, {"message": "Order deleted"})

        except Exception:
            logger.exception("Failed to delete order")
            return response(500, {"error": "Internal server error"})

    return response(404, {"error": "Not Found"})
