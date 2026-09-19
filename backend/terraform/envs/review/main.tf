variable "aws_account_id" { type = string } # export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}
variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
variable "aws_code_connection_id_to_github" { type = string } # export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

variable "route53_zone_id" { type = string } # export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

variable "db_name" { # export TF_VAR_db_name=${DB_NAME}
  type      = string
  sensitive = true
}
variable "db_host" { # export TF_VAR_db_host=${DB_HOST}
  type      = string
  sensitive = true
}
variable "db_port" { # export TF_VAR_db_port=${DB_PORT}
  type      = string
  sensitive = true
}
variable "db_user" { # export TF_VAR_db_user=${DB_USER}
  type      = string
  sensitive = true
}
variable "db_pass" { # export TF_VAR_db_pass=${DB_PASS}
  type      = string
  sensitive = true
}
variable "rails_master_key" { # export TF_VAR_rails_master_key=${RAILS_MASTER_KEY}
  type      = string
  sensitive = true
}

variable "review_backend_alarm_email" { # export TF_VAR_review_backend_alarm_email=${REVIEW_BACKEND_ALARM_EMAIL}
  type      = string
  sensitive = true
}

locals {
  stage = "review"
}

module "ecr" {
  source = "../../modules/ecr"
  stage = local.stage
}

module "cicd" {
  source = "../../modules/cicd"

  stage = local.stage
  aws_account_id = var.aws_account_id
  ecr_repository_url = module.ecr.repository_url
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
  aws_code_connection_id_to_github = var.aws_code_connection_id_to_github
}

module "ssm" {
  source = "../../modules/ssm"

  stage             = local.stage
  db_name           = var.db_name
  db_host           = var.db_host
  db_port           = var.db_port
  db_user           = var.db_user
  db_pass           = var.db_pass
  rails_master_key  = var.rails_master_key
}

module "ecs" {
  source = "../../modules/ecs"

  stage               = local.stage
  ecr_repository_url  = module.ecr.repository_url
  route53_name        = var.route53_name

  db_name_arn          = module.ssm.db_name_arn
  db_host_arn          = module.ssm.db_host_arn
  db_port_arn          = module.ssm.db_port_arn
  db_user_arn          = module.ssm.db_user_arn
  db_pass_arn          = module.ssm.db_pass_arn
  rails_master_key_arn = module.ssm.rails_master_key_arn
}

module "apigateway" {
  source = "../../modules/apigateway"

  stage           = local.stage
  route53_zone_id = var.route53_zone_id
  route53_name    = var.route53_name
}

module "alarm" {
  source = "../../modules/alarm"

  stage               = local.stage
  ecs_cluster_name    = module.ecs.cluster_name
  ecs_service_name    = module.ecs.service_name
  notification_email  = var.review_backend_alarm_email
}

module "scheduler_role" {
  source = "../../modules/scheduler_role"

  stage            = local.stage
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
  api_id           = module.apigateway.api_id
}
