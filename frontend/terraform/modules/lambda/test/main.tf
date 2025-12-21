variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}
variable "backend_origin" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}

provider "aws" {
  region = "ap-northeast-1"
}

locals {
  stage = "verify-infra"
}

module "lambda" {
  source = "../"

  stage = local.stage
  ecr_repository_url = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/nanitabe-front/next-js-on-lambda/${local.stage}"
  backend_origin = var.backend_origin
}
