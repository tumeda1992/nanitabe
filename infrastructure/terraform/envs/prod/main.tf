variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "route53_id" { type = string } # export TF_VAR_route53_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}
variable "backend_host" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}

provider "aws" {
  region = "ap-northeast-1"
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

  route53_id = var.route53_id
  route53_name = var.route53_name
  backend_host = var.backend_host
}
