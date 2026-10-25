variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

locals {
  stage = "review"
}

module "values" {
  source = "../../values"
}

# backend の review 環境を向く。本番の backend は向かない。
# github_access_token は渡さない（app は CLI で作って import する。modules/amplify/README.md 参照）
module "amplify" {
  source = "../../modules/amplify"

  appname        = module.values.appname
  stage          = local.stage
  repository_url = "https://github.com/tumeda1992/nanitabe"

  backend_origin = "https://review-backend-nanitabe.${var.route53_name}"

  branch_names = ["review"]

  custom_domain = var.route53_name
  custom_domain_sub_domains = [
    { branch_name = "review", prefix = "review-nanitabe" }
  ]
}
