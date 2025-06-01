variable "stage" { type = string }
variable "api_endpoint" { type = string }
variable "custom_domain" { type = string }
variable "route53_zone_id" { type = string }
variable "route53_name" { type = string }

module "values" {
  source = "../../values"
}

module "cert" {
  source = "./cert"
  providers = { aws = aws.us-east-1 } // このモジュールの呼び元での定義が必要

  custom_domain = var.custom_domain
  route53_zone_id = var.route53_zone_id
}

resource "aws_cloudfront_distribution" "cf" {
  aliases = [var.custom_domain]

  origin {
    # API Gateway のエンドポイントからスキームを除去して domain_name に指定
    domain_name = replace(
      replace(var.api_endpoint, "https://", ""),
      "http://", ""
    )
    origin_id   = "apiGatewayOrigin" # origin_idはディストリビューション内で一意であればいい

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    #     # CloudFront のアクセスログを S3 に出力
    #     logging_config {
    #       bucket = "${var.logging_bucket}.s3.amazonaws.com"  # S3 バケット名（末尾に .s3.amazonaws.com を付与）
    #       include_cookies = false
    #       prefix          = "cf-logs/${var.custom_domain}/"
    #     }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${module.values.appname}(${var.stage}) CDN for Next.js on API Gateway"

  default_cache_behavior {
    target_origin_id       = "apiGatewayOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET","HEAD","OPTIONS","PUT","POST","PATCH","DELETE"]
    cached_methods         = ["GET","HEAD","OPTIONS"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"       # AWS Managed – CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"   # AWS Managed – AllViewerExceptHostHeader
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # カスタムドメインをまだ設定しないフェーズなので、
  # CloudFront のデフォルト証明書（*.cloudfront.net）を利用
  viewer_certificate {
    acm_certificate_arn      = module.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }
}

# もしかしたら、route53/for_cloudfront_of_api_gatewayディレクトリにおいてもいいかもしれない
module "dns" {
  source = "./dns"

  custom_domain = var.custom_domain
  route53_zone_id = var.route53_zone_id
  cf_domain_name = aws_cloudfront_distribution.cf.domain_name
  cf_zone_id = aws_cloudfront_distribution.cf.hosted_zone_id

  depends_on = [module.cert]

}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cf.domain_name
}

output "cloudfront_hosted_zone_id" {
  value = aws_cloudfront_distribution.cf.hosted_zone_id
}
