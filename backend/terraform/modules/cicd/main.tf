variable "stage" { type = string }
variable "aws_account_id" { type = string }
variable "ecr_repository_url" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }
variable "aws_code_connection_id_to_github" { type = string }
variable "branch" {
  type = string
  default = "review"
}

module "codebuild" {
  source = "./codebuild"

  stage = var.stage
  ecr_repository_url = var.ecr_repository_url
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
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
