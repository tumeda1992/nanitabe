variable "aws_account_id" { type = string }

provider "aws" {
  region = "ap-northeast-1"
}

module "apigateway" {
  source = "../"

  stage = "deploy-test"
  lambda_function_arn = "arn:aws:lambda:ap-northeast-1:${var.aws_account_id}:function:nanitabe-front-deploy-test"
}
