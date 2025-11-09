provider "aws" {
  region = "ap-northeast-1"
}

module "prod" {
  source = "../"
}
