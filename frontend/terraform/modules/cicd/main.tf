variable "stage" { type = string }
variable "aws_account_id" { type = string }
variable "aws_access_key" { type = string } # export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID}
variable "aws_secret_access_key" { type = string } # export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
variable "backend_host" { type = string }
variable "ecr_repository_url" { type = string }
variable "lambda_function_name" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }
variable "aws_code_connection_id_to_github" { type = string }
variable "cloudfront_distribution_id" { type = string }
variable "cloudfront_domain_name" { type = string }
variable "branch" {
  type = string
  default = "master"
}

module "codebuild" {
  source = "./codebuild"

  stage = var.stage
  aws_access_key = var.aws_access_key
  aws_secret_access_key = var.aws_secret_access_key
  backend_host = var.backend_host
  ecr_repository_url = var.ecr_repository_url
  lambda_function_name = var.lambda_function_name
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  cloudfront_distribution_id = var.cloudfront_distribution_id
  cloudfront_domain_name = var.cloudfront_domain_name
}

module "codepipeline" {
  source = "./codepipeline"

  stage = var.stage
  aws_account_id = var.aws_account_id
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
  branch = var.branch
  codebuild_project_name = module.codebuild.codebuild_project_name
}
