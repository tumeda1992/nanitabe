variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCESS_KEY_ID}
variable "backend_host" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}
variable "aws_access_key" { type = string } # export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID}
variable "aws_secret_access_key" { type = string } # export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}
variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}
variable "branch" { type = string } # export TF_VAR_route53_name=main

locals {
  stage = "prod"
}

module "ecr" {
  source = "../../modules/ecr"
  stage = local.stage
}

module "lambda" {
  source = "../../modules/lambda"
  stage = local.stage
  ecr_repository_url = module.ecr.repository_url
  backend_host = var.backend_host
}

module "api_gateway" {
  source = "../../modules/apigateway"
  stage = local.stage
  lambda_function_arn = module.lambda.lambda_function_arn
}

module "s3_for_assets" {
  source = "../../modules/s3/for_assets"
  stage = local.stage
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws = aws,
    aws.us-east-1 = aws.us-east-1
  }

  stage = local.stage

  custom_domain = "nanitabe.${var.route53_name}"
  route53_zone_id = var.route53_zone_id
  route53_name = var.route53_name

  api_endpoint = module.api_gateway.api_endpoint

  assets_s3_bucket_regional_domain_name = module.s3_for_assets.bucket_regional_domain_name
  assets_s3_cloudfront_access_identity_path = module.s3_for_assets.cloudfront_origin_access_identity
}

module "cicd" {
  source = "../../modules/cicd"

  stage = local.stage
  aws_account_id = var.aws_account_id
  aws_access_key = var.aws_access_key
  aws_secret_access_key = var.aws_secret_access_key
  backend_host = var.backend_host
  ecr_repository_url = module.ecr.repository_url
  lambda_function_name = module.lambda.lambda_function_name
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
  branch = var.branch
}
