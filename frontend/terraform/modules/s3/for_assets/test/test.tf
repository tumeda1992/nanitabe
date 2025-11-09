provider "aws" {
  region = "ap-northeast-1"
}

module "s3" {
  source = "../"

  stage = "deploy-test"
}

output "bucket_regional_domain_name" {
  value = module.s3.bucket_regional_domain_name
}

output "cloudfront_origin_access_identity" {
  value = module.s3.cloudfront_origin_access_identity
}
