variable "stage" { type = string }
variable "ecr_repository_url" { type = string }
variable "backend_host" { type = string }

module "values" {
  source = "../../values"
}

locals {
  lambda_function_name = "${module.values.appname}-${var.stage}"
}

resource "aws_iam_role" "exec" {
  name = "${local.lambda_function_name}-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name = local.lambda_function_name
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:latest"
  role          = aws_iam_role.exec.arn
  architectures  = ["arm64"]

  memory_size = 1024
  timeout     = 30

  environment {
    variables = {
      # クライアント側の環境変数はyarn build時に埋め込まれるので、ここではサーバー側の環境変数のみを設定
      SERVER_SIDE_ORIGIN = "https://${var.backend_host}"
    }
  }
}

resource "aws_lambda_function_url" "this" {
  function_name       = aws_lambda_function.this.function_name
  authorization_type  = "NONE"
  invoke_mode        = "RESPONSE_STREAM"
}

output "lambda_function_arn" {
  value       = aws_lambda_function.this.arn
}

output "lambda_invoke_arn" {
  value       = aws_lambda_function.this.invoke_arn
}
