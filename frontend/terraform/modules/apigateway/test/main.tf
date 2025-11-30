variable "aws_account_id" { type = string }

provider "aws" {
  region = "ap-northeast-1"
}

locals {
  stage = "verify-infra"
}

module "apigateway" {
  source = "../"

  stage = local.stage
  lambda_function_arn = "arn:aws:lambda:ap-northeast-1:${var.aws_account_id}:function:nanitabe-front-${local.stage}"
}
