variable "stage" { type = string }
variable "lambda_function_arn" { type = string }

module "values" {
  source = "../../values"
}

locals {
  api_name = "${module.values.appname}-${var.stage}"
  lambda_invoke_arn = "arn:aws:apigateway:ap-northeast-1:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# HTTP API 作成
resource "aws_apigatewayv2_api" "this" {
  name          = local.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["content-type"]
    allow_credentials = false
    max_age = 3600
  }
}

# API Gateway 用 IAM ロール
resource "aws_iam_role" "api_gateway_role" {
  name = "${local.api_name}_api_gateway_integration_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# API Gateway 用ポリシー（Lambda 呼び出し権限）
resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "api_gateway_lambda_policy"
  role = aws_iam_role.api_gateway_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = var.lambda_function_arn
      }
    ]
  })
}

# Lambda に対する API Gateway のアクセス権限
resource "aws_lambda_permission" "api_gateway_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
}

# Lambda 統合設定
resource "aws_apigatewayv2_integration" "this" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = local.lambda_invoke_arn
  payload_format_version = "2.0"
  credentials_arn        = aws_iam_role.api_gateway_role.arn
}

# デフォルトルート
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

# CloudWatch ロググループ
resource "aws_cloudwatch_log_group" "api_logs" {
  name = "/aws/http-api/${local.api_name}"
}

# ステージ（自動デプロイ）
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format          = jsonencode({
      requestId         = "$context.requestId",
      ip                = "$context.identity.sourceIp",
      protocol          = "$context.protocol",
      status            = "$context.status",
      requestTime       = "$context.requestTime",
      httpMethod        = "$context.httpMethod",
      routeKey          = "$context.routeKey",
      responseLength    = "$context.responseLength",
      errorResponseType = "$context.error.responseType",
      errorMessage      = "$context.error.message",
      integrationErrorMessage = "$context.integration.error",
      integrationStatus = "$context.integration.integrationStatus"
    })
  }
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.this.api_endpoint
}
