variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCESS_KEY_ID}
variable "aws_access_key" { type = string } # export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID}
variable "aws_secret_access_key" { type = string } # export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

variable "backend_host" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}

variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}
variable "branch" { # export TF_VAR_route53_name=main
  type = string
  default = "main"
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  backend "s3" {
    # init実行時の引数で設定
    # 環境変数を入れ込みたかったがterraformブロックではlocalsやvariableが利用できなかったため
  }
}

module "state_in_s3" {
  source = "./state_in_s3"

  bucket_name = var.bucket_name
  dynamodb_table_name = var.dynamodb_table_name
}

module "frontend" {
  source = "../../../../frontend/terraform/envs/prod"

  providers = {
    aws = aws,
    aws.us-east-1 = aws.us-east-1
  }

  aws_account_id = var.aws_account_id
  aws_access_key = var.aws_access_key
  aws_secret_access_key = var.aws_secret_access_key
  backend_host = var.backend_host
  route53_zone_id = var.route53_zone_id
  route53_name = var.route53_name
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
  branch = var.branch
}
