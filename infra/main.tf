terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# 학습용 AWS 계정 프로필과 리전
# 다른 계정을 사용할 경우 profile을 수정해야 한다.
provider "aws" {
  profile = "project"
  region  = "ap-northeast-2"
}

locals {
  project = "serverless-orders-dev"
}
