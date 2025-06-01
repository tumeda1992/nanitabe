variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "cert" {
  source = "../"

  providers = { aws = aws.us-east-1 }

  custom_domain = "nanitabe-front-deploy-test.${var.route53_name}"
  route53_zone_id = var.route53_zone_id
}
