variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}
variable "backend_host" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}

provider "aws" {
  region = "ap-northeast-1"
}

module "lambda" {
  source = "../"

  stage = "deploy-test"
  ecr_repository_url = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/nanitabe-front/next-js-on-lambda/deploy-test"
  backend_host = var.backend_host
}
