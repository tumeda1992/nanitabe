provider "aws" {
  region = "ap-northeast-1"
}

module "ecr" {
  source = "../"

  stage = "verify-infra"
}
