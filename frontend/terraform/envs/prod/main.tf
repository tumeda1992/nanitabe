variable "route53_id" { type = string } # export TF_VAR_route53_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}


locals {
  stage = "prod"
}

module "ecr" {
  source = "../../modules/ecr"
  stage = local.stage
}
