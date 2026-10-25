import json
from app.lambda_function import lambda_handler


def make_event(method, path, body=None):
    """API Gateway HTTP API v2 이벤트를 흉내 낸다."""
    return {
        "requestContext": {"http": {"method": method}},
        "rawPath": path,
        "body": json.dumps(body) if body is not None else None,
    }


def run_test(name, event, expected_status):
    result = lambda_handler(event, None)
    actual_status = result["statusCode"]

    print(f"\n[{name}]")
    print(f"HTTP {actual_status}")
    print(result["body"])

    assert actual_status == expected_status, (
        f"Expected {expected_status}, got {actual_status}"
    )


# 정상 헬스 체크
run_test(
    "Health Check",
    make_event("GET", "/health"),
    200,
)

# 정상 주문 생성
run_test(
    "Create Order",
    make_event(
        "POST",
        "/orders",
        {"product": "Keyboard", "quantity": 2},
    ),
    201,
)

# 잘못된 주문
run_test(
    "Invalid Order",
    make_event(
        "POST",
        "/orders",
        {"product": "Mouse", "quantity": -1},
    ),
    400,
)

# 존재하지 않는 경로
run_test(
    "Not Found",
    make_event("GET", "/unknown"),
    404,
)

print("\nAll tests passed!")
