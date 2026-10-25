variable "codebuild_artifact_s3_bucket" { type = string } # export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}

variable "route53_name" { type = string } # export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

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
  ecr_repository_url = module.ecr.repository_url
  codebuild_artifact_s3_bucket = var.codebuild_artifact_s3_bucket
}

# review の SSM parameter（/nanitabe-back/review/ 配下の DB_* と RAILS_MASTER_KEY）は Terraform の管理から外した。
# AWS 上の parameter は消さず、値は scripts/review_backend/put_ssm_parameters.sh で書く。
removed {
  from = module.ssm

  lifecycle {
    destroy = false
  }
}

module "ecs" {
  source = "../../modules/ecs"

  stage               = local.stage
  ecr_repository_url  = module.ecr.repository_url
  route53_name        = var.route53_name
}

module "apigateway" {
  source = "../../modules/apigateway"

  stage           = local.stage
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
