#!/bin/bash
# review 環境（backend on ECS）を起動する。
#
# 何を行うか（design.md の workflow を参照）:
#   1. 既に desired_count=1 なら、起動中の task の開始時刻を表示して終了する
#   2. desired_count を 1 にし、task が RUNNING になるまで待つ
#   3. task の public IP を取得し、API Gateway の integration URI をその IP へ更新する
#   4. REVIEW_BACKEND_AUTO_STOP_MINUTES（既定 30）後に自動停止する one-time schedule を 2 つ作る
#   5. schedule の作成に失敗したら、desired_count と integration URI を停止側へ戻してエラー終了する
#
# 環境変数:
#   REVIEW_BACKEND_AUTO_STOP_MINUTES  自動停止までの分数（既定 30）。Phase 3 の検証で短縮して使う。
set -e

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

# 1. 既に起動中かを確認する
desired_count=$(aws ecs describe-services --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION" \
  --query 'services[0].desiredCount' --output text)

if [ "$desired_count" = "1" ]; then
  echo "既に起動中です。"
  task_arn=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --region "$REGION" \
    --query 'taskArns[0]' --output text)
  if [ "$task_arn" != "None" ] && [ -n "$task_arn" ]; then
    started_at=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$task_arn" --region "$REGION" \
      --query 'tasks[0].startedAt' --output text)
    echo "task 起動日時: ${started_at}"
  fi
  echo "URL: https://${DOMAIN}/graphql"
  exit 0
fi

# 2. desired_count を 1 にし、RUNNING になるまで待つ
echo "desired_count を 1 にします..."
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 1 --region "$REGION" >/dev/null

echo "task が RUNNING になるのを待ちます..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION"

# 3. task の ENI から public IP を取得し、integration URI を更新する
task_arn=$(aws ecs list-tasks --cluster "$CLUSTER" --service-name "$SERVICE" --region "$REGION" \
  --query 'taskArns[0]' --output text)

eni_id=$(aws ecs describe-tasks --cluster "$CLUSTER" --tasks "$task_arn" --region "$REGION" \
  --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" --output text)

public_ip=$(aws ec2 describe-network-interfaces --network-interface-ids "$eni_id" --region "$REGION" \
  --query 'NetworkInterfaces[0].Association.PublicIp' --output text)

api_id=$(aws apigatewayv2 get-apis --region "$REGION" \
  --query "Items[?Name=='${API_NAME}'].ApiId | [0]" --output text)

integration_id=$(aws apigatewayv2 get-integrations --api-id "$api_id" --region "$REGION" \
  --query 'Items[0].IntegrationId' --output text)

new_uri="http://${public_ip}:${CONTAINER_PORT}/{proxy}"

echo "integration URI を ${new_uri} へ更新します..."
aws apigatewayv2 update-integration --api-id "$api_id" --integration-id "$integration_id" \
  --integration-uri "$new_uri" --region "$REGION" >/dev/null

# 4. 自動停止用の one-time schedule を 2 つ作る（既存の同名 schedule は作り直す）
rollback() {
  echo "ERROR: 自動停止 schedule の作成に失敗した。起動を取り消し、停止側へ戻す。" >&2
  aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" >/dev/null || true
  aws apigatewayv2 update-integration --api-id "$api_id" --integration-id "$integration_id" \
    --integration-uri "$STOPPED_INTEGRATION_URI" --region "$REGION" >/dev/null || true
  exit 1
}

scheduler_role_arn=$(aws iam get-role --role-name "$SCHEDULER_ROLE_NAME" --query 'Role.Arn' --output text) || rollback

run_at=$(date -u -v"+${AUTO_STOP_MINUTES}M" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null \
  || date -u -d "+${AUTO_STOP_MINUTES} minutes" +"%Y-%m-%dT%H:%M:%S")

aws scheduler delete-schedule --name "$SCHEDULE_STOP_SERVICE" --region "$REGION" >/dev/null 2>&1 || true
aws scheduler delete-schedule --name "$SCHEDULE_STOP_INTEGRATION" --region "$REGION" >/dev/null 2>&1 || true

target_stop_service=$(jq -n \
  --arg arn "arn:aws:scheduler:::aws-sdk:ecs:updateService" \
  --arg role "$scheduler_role_arn" \
  --arg input "$(jq -n --arg cluster "$CLUSTER" --arg service "$SERVICE" '{Cluster:$cluster, Service:$service, DesiredCount:0}')" \
  '{Arn:$arn, RoleArn:$role, Input:$input}')

aws scheduler create-schedule \
  --name "$SCHEDULE_STOP_SERVICE" \
  --schedule-expression "at(${run_at})" \
  --schedule-expression-timezone "UTC" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --action-after-completion "DELETE" \
  --target "$target_stop_service" \
  --region "$REGION" >/dev/null || rollback

target_stop_integration=$(jq -n \
  --arg arn "arn:aws:scheduler:::aws-sdk:apigatewayv2:updateIntegration" \
  --arg role "$scheduler_role_arn" \
  --arg input "$(jq -n --arg apiId "$api_id" --arg integrationId "$integration_id" --arg uri "$STOPPED_INTEGRATION_URI" \
      '{ApiId:$apiId, IntegrationId:$integrationId, IntegrationUri:$uri}')" \
  '{Arn:$arn, RoleArn:$role, Input:$input}')

aws scheduler create-schedule \
  --name "$SCHEDULE_STOP_INTEGRATION" \
  --schedule-expression "at(${run_at})" \
  --schedule-expression-timezone "UTC" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --action-after-completion "DELETE" \
  --target "$target_stop_integration" \
  --region "$REGION" >/dev/null || rollback

echo "起動完了"
echo "URL: https://${DOMAIN}/graphql"
echo "自動停止予定時刻 (UTC): ${run_at}"
