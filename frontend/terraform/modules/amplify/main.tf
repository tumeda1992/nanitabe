variable "appname" { type = string }
variable "stage" { type = string }
variable "repository_url" { type = string }

variable "github_access_token" {
  type      = string
  sensitive = true
  default   = null # app の作成時だけ渡す。以後の更新は README を参照
}

variable "branch_names" { type = list(string) }

variable "backend_origin" { type = string }

# custom domain の親 domain。null のあいだは domain association を作らない。
variable "custom_domain" {
  type    = string
  default = null
}

# 親 domain 配下で、どの branch にどの sub domain（prefix）を割り当てるか。
# 例: [{ branch_name = "main", prefix = "nanitabe" }]
variable "custom_domain_sub_domains" {
  type = list(object({
    branch_name = string
    prefix      = string
  }))
  default = []
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_amplify_app" "this" {
  name         = "${var.appname}-${var.stage}"
  repository   = var.repository_url
  access_token = var.github_access_token

  lifecycle {
    # token は Terraform に通さず、手元で aws amplify update-app --access-token で更新する（README 参照）
    ignore_changes = [access_token]
  }

  # Next.js の API routes と server 側描画を使うため SSR を指定する。
  platform = "WEB_COMPUTE"

  # build 設定は repository 直下の amplify.yml を使う。
  # build_spec を指定すると repository の file より優先されるため書かない。

  environment_variables = {
    AMPLIFY_MONOREPO_APP_ROOT           = "frontend"
    NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN = var.backend_origin
  }
}

resource "aws_amplify_branch" "this" {
  for_each = toset(var.branch_names)

  app_id      = aws_amplify_app.this.id
  branch_name = each.value

  enable_auto_build = true
}

resource "aws_amplify_domain_association" "this" {
  count = var.custom_domain == null ? 0 : 1

  app_id      = aws_amplify_app.this.id
  domain_name = var.custom_domain

  # 証明書の DNS 検証の完了を apply で待たせず、状態を確認してから進める。
  wait_for_verification = false

  dynamic "sub_domain" {
    for_each = var.custom_domain_sub_domains
    content {
      branch_name = aws_amplify_branch.this[sub_domain.value.branch_name].branch_name
      prefix      = sub_domain.value.prefix
    }
  }
}

output "app_id" {
  value = aws_amplify_app.this.id
}

output "default_domain" {
  value = aws_amplify_app.this.default_domain
}

output "branch_urls" {
  value = {
    for name, branch in aws_amplify_branch.this :
    name => "https://${branch.branch_name}.${aws_amplify_app.this.default_domain}"
  }
}

output "custom_domain_certificate_verification_dns_record" {
  value = try(aws_amplify_domain_association.this[0].certificate_verification_dns_record, null)
}

output "custom_domain_sub_domains" {
  value = try(aws_amplify_domain_association.this[0].sub_domain, null)
}
