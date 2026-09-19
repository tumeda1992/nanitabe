variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}
variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

locals {
  stage = "review"
}

module "ecr" {
  source = "../../modules/ecr"
  stage = local.stage
}

module "cicd" {
  source = "../../modules/cicd"

  stage = local.stage
  aws_account_id = var.aws_account_id
  ecr_repository_url = module.ecr.repository_url
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
}
