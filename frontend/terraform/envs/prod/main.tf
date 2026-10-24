variable "backend_origin" { type = string } # export TF_VAR_backend_origin=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}
variable "amplify_github_access_token" { # export TF_VAR_amplify_github_access_token=${AMPLIFY_GITHUB_ACCESS_TOKEN}
  type      = string
  sensitive = true
}

locals {
  stage = "prod"
}

module "values" {
  source = "../../values"
}

module "amplify" {
  source = "../../modules/amplify"

  appname        = module.values.appname
  stage          = local.stage
  repository_url = "https://github.com/tumeda1992/nanitabe"

  github_access_token = var.amplify_github_access_token
  backend_origin      = var.backend_origin

  branch_names = ["main"]

  custom_domain = var.route53_name
  custom_domain_sub_domains = [
    { branch_name = "main", prefix = "nanitabe" }
  ]
}
