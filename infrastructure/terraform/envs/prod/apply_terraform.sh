# 事前に環境変数を設定。
export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

export TF_VAR_backend_origin=${NEXT_PUBLIC_CLIENT_SIDE_PROD_ORIGIN}

export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

export TF_VAR_amplify_github_access_token=${AMPLIFY_GITHUB_ACCESS_TOKEN}

terraform apply
