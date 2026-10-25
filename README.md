# Serverless Orders API

AWS 서버리스 서비스를 이용해 구축한 주문 관리 REST API 프로젝트입니다.

## Architecture

Client
  → API Gateway (HTTP API)
  → AWS Lambda (Python 3.12)
  → Amazon DynamoDB

운영 및 배포:
- Terraform: AWS 인프라 관리
- GitHub Actions: Lambda 코드 자동 배포
- GitHub OIDC: Access Key 없이 AWS 인증
- CloudWatch Logs: 애플리케이션 로그 및 장애 분석

## Features

| Method | Endpoint | Description |
|---|---|---|
| GET | /health | 상태 확인 |
| POST | /orders | 주문 생성 |
| GET | /orders/{orderId} | 주문 조회 |
| DELETE | /orders/{orderId} | 주문 삭제 |

## Tech Stack

- Python 3.12
- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Amazon CloudWatch
- AWS IAM
- Terraform
- GitHub Actions

## CI/CD

1. main 브랜치에 코드 Push
2. GitHub Actions 실행
3. GitHub OIDC를 이용해 AWS IAM 역할 획득
4. Lambda 코드 ZIP 패키징
5. Lambda 함수 코드 업데이트
6. API Gateway를 통해 배포 결과 확인

## Troubleshooting

### DynamoDB Decimal serialization error

문제:
- POST /orders는 정상 동작
- GET /orders/{orderId}에서 HTTP 500 발생

원인:
- DynamoDB 조회 결과의 숫자가 Python Decimal 타입으로 반환됨
- json.dumps()가 Decimal을 기본적으로 직렬화하지 못함

해결:
- CloudWatch Logs에서 TypeError 확인
- Decimal 변환 함수를 추가
- Terraform으로 Lambda 코드 재배포
- 주문 조회 HTTP 200 확인

## Security

- Lambda 실행 역할에 DynamoDB 최소 권한 적용
- 지정된 DynamoDB 테이블에만 접근 허용
- GitHub Actions는 OIDC 임시 자격 증명 사용
- 배포 역할은 지정된 Lambda 함수의 코드 업데이트로 제한

## Limitations

학습용 프로젝트로 API 인증은 구현하지 않았습니다.
실제 운영에서는 JWT 인증, 요청 검증, 중복 주문 방지,
API 모니터링 및 배포 롤백 전략이 추가로 필요합니다.

## Cleanup

cd infra
terraform destroy
