variable "route53_zone_id" { type = string } # export TF_VAR_route53_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

provider "aws" {
  region = "ap-northeast-1"
}

module "dns" {
  source = "../"

  custom_domain = "nanitabe-front-deploy-test.${var.route53_name}"
  route53_zone_id = var.route53_zone_id
  cf_domain_name = "d1qmtpt8svn0j2.cloudfront.net"
  cf_zone_id = "Z2FDTNDATAQYW2" # CloudFrontのゾーンIDはディストリビューションに限らず固定値
}
