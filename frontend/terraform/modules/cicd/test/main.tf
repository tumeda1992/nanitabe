variable "aws_account_id" { type = string }
variable "aws_access_key" { type = string } # export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID}
variable "aws_secret_access_key" { type = string } # export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
variable "backend_host" { type = string }
variable "ecr_repository_url" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }
variable "aws_code_connection_id_to_github" { type = string }
variable "branch" {
  type = string
  default = "master"
}

provider "aws" {
  region = "ap-northeast-1"
}

module "codebuild" {
  source = "../"

  stage = "deploy-test"
  aws_account_id = var.aws_account_id
  aws_access_key = var.aws_access_key
  aws_secret_access_key = var.aws_secret_access_key
  backend_host = var.backend_host
  ecr_repository_url = var.ecr_repository_url
  lambda_function_name = "nanitabe-front-deploy-test"
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
  branch = var.branch
}
