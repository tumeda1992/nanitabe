variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}
variable "backend_host" { type = string } # export TF_VAR_backend_host=${BACKEND_PROD_HOST}

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

module "cloudfront" {
  source = "../../modules/cloudfront"

  providers = {
    aws = aws,
    aws.us-east-1 = aws.us-east-1
  }

  stage = local.stage
  api_endpoint = module.api_gateway.api_endpoint
  custom_domain = "nanitabe-front.${var.route53_name}"
  route53_zone_id = var.route53_zone_id
  route53_name = var.route53_name
}
