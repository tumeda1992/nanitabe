variable "stage" { type = string }

variable "db_name" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type      = string
  sensitive = true
}

variable "db_user" {
  type      = string
  sensitive = true
}

variable "db_pass" {
  type      = string
  sensitive = true
}

variable "rails_master_key" {
  type      = string
  sensitive = true
}

module "values" {
  source = "../../values"
}

locals {
  prefix = "/${module.values.appname}/${var.stage}"
}

resource "aws_ssm_parameter" "db_name" {
  name  = "${local.prefix}/DB_NAME"
  type  = "SecureString"
  value = var.db_name
}

resource "aws_ssm_parameter" "db_host" {
  name  = "${local.prefix}/DB_HOST"
  type  = "SecureString"
  value = var.db_host
}

resource "aws_ssm_parameter" "db_port" {
  name  = "${local.prefix}/DB_PORT"
  type  = "SecureString"
  value = var.db_port
}

resource "aws_ssm_parameter" "db_user" {
  name  = "${local.prefix}/DB_USER"
  type  = "SecureString"
  value = var.db_user
}

resource "aws_ssm_parameter" "db_pass" {
  name  = "${local.prefix}/DB_PASS"
  type  = "SecureString"
  value = var.db_pass
}

resource "aws_ssm_parameter" "rails_master_key" {
  name  = "${local.prefix}/RAILS_MASTER_KEY"
  type  = "SecureString"
  value = var.rails_master_key
}

output "db_name_arn" { value = aws_ssm_parameter.db_name.arn }
output "db_host_arn" { value = aws_ssm_parameter.db_host.arn }
output "db_port_arn" { value = aws_ssm_parameter.db_port.arn }
output "db_user_arn" { value = aws_ssm_parameter.db_user.arn }
output "db_pass_arn" { value = aws_ssm_parameter.db_pass.arn }
output "rails_master_key_arn" { value = aws_ssm_parameter.rails_master_key.arn }
