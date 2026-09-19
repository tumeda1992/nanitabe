#!/bin/bash
# review 環境（backend on ECS）を停止する。
#
# 何を行うか（design.md の workflow を参照）:
#   1. desired_count を 0 にする
#   2. API Gateway の integration URI を到達しない値へ戻す
#   3. 自動停止用の one-time schedule を 2 つ削除する
#
# すべて冪等。既に停止している状態で実行しても、schedule が無い状態で実行してもエラーにしない。
set -e

export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

REGION="ap-northeast-1"
CLUSTER="nanitabe-back-review"
SERVICE="nanitabe-back_service_review"
API_NAME="nanitabe-back-review"
CONTAINER_PORT=18101
STOPPED_INTEGRATION_URI="http://192.0.2.1:${CONTAINER_PORT}/{proxy}"
SCHEDULE_STOP_SERVICE="nanitabe-back_review_auto_stop_service"
SCHEDULE_STOP_INTEGRATION="nanitabe-back_review_auto_stop_integration"

echo "desired_count を 0 にします..."
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" >/dev/null

api_id=$(aws apigatewayv2 get-apis --region "$REGION" \
  --query "Items[?Name=='${API_NAME}'].ApiId | [0]" --output text)

integration_id=$(aws apigatewayv2 get-integrations --api-id "$api_id" --region "$REGION" \
  --query 'Items[0].IntegrationId' --output text)

echo "integration URI を停止側の値へ戻します..."
aws apigatewayv2 update-integration --api-id "$api_id" --integration-id "$integration_id" \
  --integration-uri "$STOPPED_INTEGRATION_URI" --region "$REGION" >/dev/null

echo "自動停止 schedule を削除します（存在しなければ何もしない）..."
aws scheduler delete-schedule --name "$SCHEDULE_STOP_SERVICE" --region "$REGION" >/dev/null 2>&1 || true
aws scheduler delete-schedule --name "$SCHEDULE_STOP_INTEGRATION" --region "$REGION" >/dev/null 2>&1 || true

echo "停止完了"
