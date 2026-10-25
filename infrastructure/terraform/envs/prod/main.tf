variable "bucket_name" { type = string } # export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
variable "dynamodb_table_name" { type = string } # export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

variable "backend_origin" { type = string } # export TF_VAR_backend_origin=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN}

variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

variable "amplify_github_access_token" { # app を作り直すときだけ export TF_VAR_amplify_github_access_token=${AMPLIFY_GITHUB_ACCESS_TOKEN}
  type      = string
  sensitive = true
  default   = null
}

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

  backend_origin              = var.backend_origin
  route53_name                = var.route53_name
  amplify_github_access_token = var.amplify_github_access_token
}

module "github_oidc" {
  source = "../../modules/github_oidc"

  repository        = "tumeda1992/nanitabe"
  name_prefix       = "nanitabe"
  state_bucket_name = var.bucket_name
  lock_table_name   = var.dynamodb_table_name
}
