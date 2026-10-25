#!/bin/bash
# review 環境の SSM parameter（/nanitabe-back/review/ 配下の 6 つ）へ、.env の値を書く。
# これらの parameter は Terraform の管理外（値を Terraform の state と GitHub secrets に残さないため）。
# 値を変えたときに実行する。認証情報は AWS CLI の設定から得る（.env の AWS key は使わない）。
# ECS の task definition の valueFrom と task execution role は、同じ名前を ARN として参照している
# （backend/terraform/modules/ecs/main.tf）。名前を変えるときは両方を変える。
set -euo pipefail

ENV_FILE="/etc/opt/app_setting_files/nanitabe/.env"
REGION="ap-northeast-1"
PREFIX="/nanitabe-back/review"

get() {
  local line
  line=$(grep -E "^$1=" "$ENV_FILE" | head -n 1) || true
  [ -n "$line" ] || { echo "ERROR: .env に $1 が無い" >&2; exit 1; }
  local v="${line#*=}"
  v="${v%\"}"; v="${v#\"}"; v="${v%\'}"; v="${v#\'}"
  printf '%s' "$v"
}

for key in DB_NAME DB_HOST DB_PORT DB_USER DB_PASS RAILS_MASTER_KEY; do
  aws ssm put-parameter --region "$REGION" --name "${PREFIX}/${key}" \
    --type SecureString --overwrite --value "$(get "$key")" > /dev/null
  echo "put: ${PREFIX}/${key}"
done
