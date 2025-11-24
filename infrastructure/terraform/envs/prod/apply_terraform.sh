# 事前に環境変数を設定。
export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}
export TF_VAR_aws_access_key=${AWS_ACCESS_KEY_ID}
export TF_VAR_aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

export TF_VAR_backend_host=${BACKEND_PROD_HOST}

export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

terraform apply
