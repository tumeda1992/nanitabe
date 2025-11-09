variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# 起動・停止ともに5分くらいかかる
module "cloudfront" {
  source = "../"

  providers = {
    aws = aws,
    aws.us-east-1 = aws.us-east-1
  }

  stage = "deploy-test"
  api_endpoint = "https://xl40c159a4.execute-api.ap-northeast-1.amazonaws.com"
  custom_domain = "nanitabe-front-deploy-test.${var.route53_name}"
  route53_zone_id = var.route53_zone_id
  route53_name = var.route53_name
  assets_s3_bucket_regional_domain_name = "nanitabe-front-deploy-test-static-files.s3.ap-northeast-1.amazonaws.com"
  assets_s3_cloudfront_access_identity_path = "origin-access-identity/cloudfront/E3ONVKYK1RA21W"
}
