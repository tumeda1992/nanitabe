variable "stage" { type = string }
variable "route53_name" { type = string }
variable "discovery_service_arn" { type = string }
variable "vpc_link_security_group_id" { type = string }
variable "vpc_link_subnet_ids" {
  type = list(string)
  validation {
    condition     = length(var.vpc_link_subnet_ids) > 0
    error_message = "At least one supported VPC link subnet is required."
  }
}

# zone は route53_name から引く（prod と共有の zone）。
data "aws_route53_zone" "this" {
  name = var.route53_name
}

module "values" {
  source = "../../values"
}

locals {
  api_name      = "${module.values.appname}-${var.stage}"
  custom_domain = "review-backend-nanitabe.${var.route53_name}"
}

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = local.api_name
  security_group_ids = [var.vpc_link_security_group_id]
  subnet_ids         = var.vpc_link_subnet_ids
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = var.discovery_service_arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.this.id
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:header.Host" = local.custom_domain
    "overwrite:path"        = "$request.path"
  }
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name = "/aws/http-api/${local.api_name}"
  # retention_in_days は設定しない（無期限保持）
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      ip                      = "$context.identity.sourceIp"
      protocol                = "$context.protocol"
      status                  = "$context.status"
      requestTime             = "$context.requestTime"
      httpMethod              = "$context.httpMethod"
      routeKey                = "$context.routeKey"
      responseLength          = "$context.responseLength"
      errorResponseType       = "$context.error.responseType"
      errorMessage            = "$context.error.message"
      integrationErrorMessage = "$context.integration.error"
      integrationStatus       = "$context.integration.integrationStatus"
    })
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.custom_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "this" {
  domain_name = local.custom_domain

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.cert.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  domain_name = aws_apigatewayv2_domain_name.this.id
  stage       = aws_apigatewayv2_stage.default.id
}

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.custom_domain
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.this.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "api_id" { value = aws_apigatewayv2_api.this.id }
output "api_name" { value = local.api_name }
output "integration_id" { value = aws_apigatewayv2_integration.this.id }
output "custom_domain" { value = local.custom_domain }
output "vpc_link_id" { value = aws_apigatewayv2_vpc_link.this.id }
