variable "stage" { type = string }
variable "backend_host" { type = string }
variable "aws_access_key" { type = string } # TODO: secret化する
variable "aws_secret_access_key" { type = string }
variable "ecr_repository_url" { type = string }
variable "lambda_function_name" { type = string }
variable "codebuild_artifact_s3_bucket" { type = string }

module "values" {
  source = "../../../values/"
}

resource "aws_codebuild_project" "codebuild_project" {
  name         = "${module.values.appname}_build_${var.stage}"
  service_role = aws_iam_role.codebuild_role.arn

  environment {
    type            = "ARM_CONTAINER"
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-aarch64-standard:2.0"
    privileged_mode = true  # Docker 使用時は必要

    environment_variable {
      name  = "ECR_REPO_URI"
      value = var.ecr_repository_url
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "LAMBDA_FUNCTION_NAME"
      value = var.lambda_function_name
    }

    environment_variable {
      name  = "AWS_ACCESS_KEY_ID"
      value = var.aws_access_key
    }

    environment_variable {
      name  = "AWS_SECRET_ACCESS_KEY"
      value = var.aws_secret_access_key
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-northeast-1"
    }

    environment_variable {
      name  = "BACKEND_HOST"
      value = var.backend_host
    }

    environment_variable {
      name  = "DEPLOY_ENV"
      value = var.stage
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "frontend/terraform/modules/cicd/codebuild/buildspec.yml"
  }

  artifacts {
    type     = "CODEPIPELINE"
    location = var.codebuild_artifact_s3_bucket
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "${module.values.appname}_${var.stage}_codebuild_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy" "codebuild_log_policy" {
  name = "${module.values.appname}_${var.stage}_cloudwatch_log_policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_s3_policy" {
  name = "${module.values.appname}_${var.stage}_s3_policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketLocation",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.codebuild_artifact_s3_bucket}",
          "arn:aws:s3:::${var.codebuild_artifact_s3_bucket}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_lambda_policy" {
  name = "${module.values.appname}_${var.stage}_lambda_policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:GetFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

output "codebuild_project_name" {
  value = aws_codebuild_project.codebuild_project.name
}
