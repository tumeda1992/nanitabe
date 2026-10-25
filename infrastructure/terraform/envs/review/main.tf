variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}

variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

variable "review_backend_alarm_email" {
  type      = string
  sensitive = true
} # export TF_VAR_review_backend_alarm_email=${REVIEW_BACKEND_ALARM_EMAIL}

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

  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket

  route53_name                 = var.route53_name

  review_backend_alarm_email = var.review_backend_alarm_email
}

module "frontend" {
  source = "../../../../frontend/terraform/envs/review"

  route53_name = var.route53_name
}

# 取り込み後に削除する（app は CLI で作成済み。frontend/terraform/modules/amplify/README.md 参照）
import {
  to = module.frontend.module.amplify.aws_amplify_app.this
  id = "dbojsgkwxbq4g"
}
