variable "stage" { type = string }
variable "api_endpoint" { type = string }

module "values" {
  source = "../../values"
}

resource "aws_cloudfront_distribution" "cf" {
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
    cloudfront_default_certificate = true
  }
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cf.domain_name
}
