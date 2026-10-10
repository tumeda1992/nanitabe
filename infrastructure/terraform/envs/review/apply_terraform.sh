# 事前に環境変数を設定。
export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

export TF_VAR_bucket_name=${TERRAFROM_STATE_S3_BUCKET}
export TF_VAR_dynamodb_table_name=${TERRAFROM_STATE_DYNAMODB_TABLE}

export TF_VAR_aws_account_id=${AWS_ACCOUNT_ID}

export TF_VAR_codebuild_artifact_s3_bucket=${CODEBUILD_ARTICACT_S3_BUCKET}
export TF_VAR_aws_code_connection_id_to_github=${AWS_CODE_CONNECTION_ID_TO_GITHUB}

export TF_VAR_route53_zone_id=${ROUTE53_HOSTZONE_ID}
export TF_VAR_route53_name=${ROUTE53_HOSTZONE_NAME}

export TF_VAR_db_name=${DB_NAME}
export TF_VAR_db_host=${DB_HOST}
export TF_VAR_db_port=${DB_PORT}
export TF_VAR_db_user=${DB_USER}
export TF_VAR_db_pass=${DB_PASS}
export TF_VAR_rails_master_key=${RAILS_MASTER_KEY}

export TF_VAR_review_backend_alarm_email=${REVIEW_BACKEND_ALARM_EMAIL}

set -e

# review 環境に閉じる操作の条件（destroy を含まないこと）を script 自身で確認する。
# 詳細は backend/docs/ai_guideline/development_standard/review_environment.md の「review 環境に閉じる操作」。
terraform plan -out=tfplan.review

destroy_count=$(terraform show -json tfplan.review | python3 -c "
import json, sys
plan = json.load(sys.stdin)
print(sum(1 for change in plan.get('resource_changes', [])
          if 'delete' in change['change']['actions']))
")

if [ "$destroy_count" -ne 0 ]; then
  echo "ERROR: plan に destroy が ${destroy_count} 件含まれる。apply せず停止する。"
  echo "差分を確認し、意図した destroy であればこの script を使わず手順を判断すること。"
  exit 1
fi

terraform apply tfplan.review
