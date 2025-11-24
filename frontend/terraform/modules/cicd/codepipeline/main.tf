variable "stage" { type = string }
variable "aws_account_id" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }
variable "aws_code_connection_id_to_github" { type = string }
variable "codebuild_project_name" { type = string }
variable "branch" { type = string }

module "values" {
  source = "../../../values/"
}

locals {
  aws_code_connection_github_arn = "arn:aws:codeconnections:ap-northeast-1:${var.aws_account_id}:connection/${var.aws_code_connection_id_to_github}"
}

resource "aws_codepipeline" "pipeline" {
  name     = "${module.values.appname}_codepipeline_${var.stage}"
  role_arn = aws_iam_role.codepipeline_role.arn


  artifact_store {
    type     = "S3"
    location = var.codebuild_artifact_s3_bucket
  }

  stage {
    name = "Source"

    action {
      name      = "SourceAction"
      run_order = 1

      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"

      configuration = {
        FullRepositoryId     = "tumeda1992/nanitabe"
        BranchName           = var.branch
        ConnectionArn        = local.aws_code_connection_github_arn
        OutputArtifactFormat = "CODE_ZIP"
      }

      output_artifacts = ["source_output"]
    }
  }


  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      run_order        = 2
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      configuration    = {
        "ProjectName" = var.codebuild_project_name
      }
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      role_arn         = aws_iam_role.codepipeline_role.arn
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${module.values.appname}_codepipeline_${var.stage}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "codepipeline.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name        = "${module.values.appname}_codepipeline_${var.stage}_policy"
  role       = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:CreateBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "codebuild:BatchGetBuilds"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "codebuild:StartBuild"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "codecommit:GitPull"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codestar-connections:UseConnection",
          "codeconnections:UseConnection"
        ]
        Effect   = "Allow"
        Resource = local.aws_code_connection_github_arn
      }
    ]
  })
}
