variable "stage" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "api_id" { type = string }

module "values" {
  source = "../../values"
}

data "aws_caller_identity" "current" {}

locals {
  role_name = "${module.values.appname}_${var.stage}_scheduler_role"
}

resource "aws_iam_role" "scheduler" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "scheduler.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${local.role_name}_policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService"]
        Resource = "arn:aws:ecs:ap-northeast-1:${data.aws_caller_identity.current.account_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"
      },
      {
        # API Gateway v2 の管理APIはHTTP verb単位のIAM actionで認可される。
        # apigatewayv2:UpdateIntegration という action 名は実際には評価されず、
        # apigateway:PATCH が要求される（CloudTrailのAccessDeniedで実測して判明）。
        Effect   = "Allow"
        Action   = ["apigateway:PATCH", "apigateway:GET"]
        Resource = "arn:aws:apigateway:ap-northeast-1::/apis/${var.api_id}/integrations/*"
      }
    ]
  })
}

output "role_arn" { value = aws_iam_role.scheduler.arn }
