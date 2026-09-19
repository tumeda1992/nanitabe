variable "stage" { type = string }
variable "route53_zone_id" { type = string }
variable "route53_name" { type = string }

module "values" {
  source = "../../values"
}

locals {
  api_name       = "${module.values.appname}-${var.stage}"
  custom_domain  = "review-backend-nanitabe.${var.route53_name}"
  container_port = 18101
  # 起動していない状態を表す到達しないIP（TEST-NET-1, RFC 5737）
  stopped_integration_uri = "http://192.0.2.1:${local.container_port}/{proxy}"
}

resource "aws_apigatewayv2_api" "this" {
  name          = local.api_name
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "this" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = local.stopped_integration_uri
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:header.Host" = local.custom_domain
  }

  # integration_uri は起動・停止 script が実行時に書き換える。
  # terraform apply のたびに起動中の環境の転送先が停止側の値へ戻らないようにする
  lifecycle {
    ignore_changes = [integration_uri]
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
      requestId              = "$context.requestId"
      ip                     = "$context.identity.sourceIp"
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

  zone_id = var.route53_zone_id
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
  zone_id = var.route53_zone_id
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
output "stopped_integration_uri" { value = local.stopped_integration_uri }
output "container_port" { value = local.container_port }
