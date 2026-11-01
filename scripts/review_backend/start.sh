#!/bin/bash
# review 環境（backend on ECS）を起動する。
#
# 何を行うか（design.md の workflow を参照）:
#   1. 既に desired_count=1 の場合も、integration と自動停止 schedule を再整合する
#   2. desired_count を 1 にし、task が RUNNING になるまで待つ
#   3. task の public IP を取得し、API Gateway の integration URI をその IP へ更新する
#   4. REVIEW_BACKEND_AUTO_STOP_MINUTES（既定 30）後に自動停止する one-time schedule を 2 つ作る
#   5. 途中で失敗・割込みがあれば、desired_count と integration URI の停止を試みてエラー終了する
#
# 環境変数:
#   REVIEW_BACKEND_AUTO_STOP_MINUTES  自動停止までの分数（既定 30）。Phase 3 の検証で短縮して使う。
set -euo pipefail

export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

REGION="ap-northeast-1"
CLUSTER="nanitabe-back-review"
SERVICE="nanitabe-back_service_review"
API_NAME="nanitabe-back-review"
SCHEDULER_ROLE_NAME="nanitabe-back_review_scheduler_role"
CONTAINER_PORT=18101
STOPPED_INTEGRATION_URI="http://192.0.2.1:${CONTAINER_PORT}/{proxy}"
AUTO_STOP_MINUTES="${REVIEW_BACKEND_AUTO_STOP_MINUTES:-30}"
DOMAIN="review-backend-nanitabe.${ROUTE53_HOSTZONE_NAME}"
SCHEDULE_STOP_SERVICE="nanitabe-back_review_auto_stop_service"
SCHEDULE_STOP_INTEGRATION="nanitabe-back_review_auto_stop_integration"

rollback_required=0
api_id=""
integration_id=""

require_value() {
  if [[ -z "$2" || "$2" == "None" || "$2" == "null" ]]; then
    echo "ERROR: $1 を取得できませんでした。" >&2
    return 1
  fi
}

rollback_on_exit() {
  status=$?
  trap - EXIT INT TERM
  if (( status != 0 && rollback_required == 1 )); then
    set +e
    echo "ERROR: 起動を中断しました。rollbackで停止を試みます。" >&2
    if ! aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" >/dev/null; then
      echo "ERROR: ECS の停止に失敗しました。状態確認と停止が必要です。" >&2
    fi
    if require_value "api_id" "$api_id" >/dev/null 2>&1 && require_value "integration_id" "$integration_id" >/dev/null 2>&1; then
      if ! aws apigatewayv2 update-integration --api-id "$api_id" --integration-id "$integration_id" \
        --integration-uri "$STOPPED_INTEGRATION_URI" --region "$REGION" >/dev/null; then
        echo "ERROR: integration の停止に失敗しました。状態確認が必要です。" >&2
      fi
    else
      echo "ERROR: integration ID が未確定のため停止設定を確認できません。" >&2
    fi
  fi
  exit "$status"
}
trap rollback_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! "$AUTO_STOP_MINUTES" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: REVIEW_BACKEND_AUTO_STOP_MINUTES は正の整数で指定してください。" >&2
  exit 1
fi

delete_schedule_if_exists() {
  local error_message status
  if error_message=$(aws scheduler delete-schedule --name "$1" --region "$REGION" 2>&1); then
    return 0
  else
    status=$?
  fi
  if [[ "$error_message" == *"(ResourceNotFoundException)"* ]]; then
    return 0
  fi
  printf '%s\n' "$error_message" >&2
  return "$status"
}

# 1. 既に起動中かを確認する
desired_count=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" \
  --query 'services[0].desiredCount' --output text)

require_value "desired_count" "$desired_count"
if [[ "$desired_count" != "0" && "$desired_count" != "1" ]]; then
  echo "ERROR: desired_count は 0 または 1 である必要があります。" >&2
  exit 1
fi
if [ "$desired_count" = "1" ]; then
  echo "既に起動中です。停止設定を再整合します。"
  rollback_required=1
fi

api_id=$(aws apigatewayv2 get-apis --region "$REGION" \
  --query "Items[?Name=='${API_NAME}'].ApiId | [0]" --output text)

require_value "api_id" "$api_id"

integration_id=$(aws apigatewayv2 get-integrations --api-id "$api_id" --region "$REGION" \
  --query 'Items[0].IntegrationId' --output text)

require_value "integration_id" "$integration_id"

scheduler_role_arn=$(aws iam get-role --role-name "$SCHEDULER_ROLE_NAME" --query 'Role.Arn' --output text)

require_value "scheduler role" "$scheduler_role_arn"

target_stop_service=$(jq -n \
  --arg arn "arn:aws:scheduler:::aws-sdk:ecs:updateService" \
  --arg role "$scheduler_role_arn" \
  --arg input "$(jq -n --arg cluster "$CLUSTER" --arg service "$SERVICE" '{Cluster:$cluster, Service:$service, DesiredCount:0}')" \
  '{Arn:$arn, RoleArn:$role, Input:$input}')

target_stop_integration=$(jq -n \
  --arg arn "arn:aws:scheduler:::aws-sdk:apigatewayv2:updateIntegration" \
  --arg role "$scheduler_role_arn" \
  --arg input "$(jq -n --arg apiId "$api_id" --arg integrationId "$integration_id" --arg uri "$STOPPED_INTEGRATION_URI" \
      '{ApiId:$apiId, IntegrationId:$integrationId, IntegrationUri:$uri}')" \
  '{Arn:$arn, RoleArn:$role, Input:$input}')

# 2. desired_count を 1 にし、RUNNING になるまで待つ
echo "desired_count を 1 にします..."
rollback_required=1
if [ "$desired_count" != "1" ]; then
  aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 1 --region "$REGION" >/dev/null
fi

echo "task が RUNNING になるのを待ちます..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION"

# 3. task の ENI から public IP を取得し、integration URI を更新する
task_arn=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --region "$REGION" \
  --query 'taskArns[0]' --output text)

require_value "task ARN" "$task_arn"

eni_id=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$task_arn" --region "$REGION" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" --output text)

require_value "network interface" "$eni_id"

public_ip=$(aws ec2 describe-network-interfaces --network-interface-ids "$eni_id" --region "$REGION" \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

require_value "public IP" "$public_ip"
if [[ ! "$public_ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "ERROR: public IP が IPv4 address ではありません。" >&2
  exit 1
fi
IFS=. read -r -a ip_octets <<< "$public_ip"
for octet in "${ip_octets[@]}"; do
  if (( 10#$octet > 255 )); then
    echo "ERROR: public IP が IPv4 address ではありません。" >&2
    exit 1
  fi
done

new_uri="http://${public_ip}:${CONTAINER_PORT}/{proxy}"

echo "integration URI を ${new_uri} へ更新します..."
aws apigatewayv2 update-integration --api-id "$api_id" --integration-id "$integration_id" \
  --integration-uri "$new_uri" --region "$REGION" >/dev/null

run_at=$(date -u -v"+${AUTO_STOP_MINUTES}M" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null \
  || date -u -d "+${AUTO_STOP_MINUTES} minutes" +"%Y-%m-%dT%H:%M:%S")

require_value "schedule date" "$run_at"

# 4. 自動停止用の one-time schedule を 2 つ作る（既存の同名 schedule は作り直す）
delete_schedule_if_exists "$SCHEDULE_STOP_SERVICE"
delete_schedule_if_exists "$SCHEDULE_STOP_INTEGRATION"

aws scheduler create-schedule \
  --name "$SCHEDULE_STOP_SERVICE" \
  --schedule-expression "at(${run_at})" \
  --schedule-expression-timezone "UTC" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --action-after-completion "DELETE" \
  --target "$target_stop_service" \
  --region "$REGION" >/dev/null

aws scheduler create-schedule \
  --name "$SCHEDULE_STOP_INTEGRATION" \
  --schedule-expression "at(${run_at})" \
  --schedule-expression-timezone "UTC" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --action-after-completion "DELETE" \
  --target "$target_stop_integration" \
  --region "$REGION" >/dev/null

rollback_required=0
echo "起動完了"
echo "URL: https://${DOMAIN}/graphql"
echo "自動停止予定時刻 (UTC): ${run_at}"
