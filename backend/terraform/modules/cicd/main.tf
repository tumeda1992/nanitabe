variable "stage" { type = string }
variable "ecr_repository_url" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }
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
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  branch = var.branch
  codebuild_project_name = module.codebuild.codebuild_project_name
}
