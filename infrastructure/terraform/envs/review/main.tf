variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}

variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    # init実行時の引数で設定
  }
}

module "backend" {
  source = "../../../../backend/terraform/envs/review"

  aws_account_id = var.aws_account_id
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
}
