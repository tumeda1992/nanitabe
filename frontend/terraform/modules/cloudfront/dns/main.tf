variable "custom_domain" { type = string }
variable "route53_zone_id" { type = string }
variable "cf_domain_name" { type = string }
variable "cf_zone_id" { type = string }

resource "aws_route53_record" "cf_alias_a" {
  zone_id = var.route53_zone_id
  name    = var.custom_domain
  type    = "A" # IPv4用

  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cf_alias_aaaa" {
  zone_id = var.route53_zone_id
  name    = var.custom_domain
  type    = "AAAA" # IPv6用

  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}
