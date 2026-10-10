variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}

variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

variable "db_name" {
  type      = string
  sensitive = true
} # export TF_VAR_db_name=${DB_NAME}
variable "db_host" {
  type      = string
  sensitive = true
} # export TF_VAR_db_host=${DB_HOST}
variable "db_port" {
  type      = string
  sensitive = true
} # export TF_VAR_db_port=${DB_PORT}
variable "db_user" {
  type      = string
  sensitive = true
} # export TF_VAR_db_user=${DB_USER}
variable "db_pass" {
  type      = string
  sensitive = true
} # export TF_VAR_db_pass=${DB_PASS}
variable "rails_master_key" {
  type      = string
  sensitive = true
} # export TF_VAR_rails_master_key=${RAILS_MASTER_KEY}

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

  aws_account_id = var.aws_account_id
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github

  route53_zone_id = var.route53_zone_id
  route53_name    = var.route53_name

  db_name          = var.db_name
  db_host          = var.db_host
  db_port          = var.db_port
  db_user          = var.db_user
  db_pass          = var.db_pass
  rails_master_key = var.rails_master_key

  review_backend_alarm_email = var.review_backend_alarm_email
}
