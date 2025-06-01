provider "aws" {
  region = "ap-northeast-1"
}

module "s3" {
  source = "../"

  stage = "deploy-test"
}
