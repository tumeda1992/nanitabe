#!/bin/bash
# review 環境（backend on ECS）を停止する。
#
# 何を行うか（design.md の workflow を参照）:
#   1. desired_count を 0 にする
#   2. taskの終了を待ち、Cloud Mapに稼働endpointを残さない
#   3. 自動停止scheduleと移行前のURI停止scheduleを削除する
#
# すべて冪等。既に停止している状態で実行しても、schedule が無い状態で実行してもエラーにしない。
set -euo pipefail

export $(grep -v '^#' /etc/opt/app_setting_files/nanitabe/.env | xargs)

REGION="ap-northeast-1"
CLUSTER="nanitabe-back-review"
SERVICE="nanitabe-back_service_review"
SCHEDULE_STOP_SERVICE="nanitabe-back_review_auto_stop_service"
SCHEDULE_STOP_INTEGRATION="nanitabe-back_review_auto_stop_integration"

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

echo "desired_count を 0 にします..."
aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" >/dev/null

echo "task の停止を待ちます..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION"

echo "自動停止 schedule を削除します（存在しなければ何もしない）..."
delete_schedule_if_exists "$SCHEDULE_STOP_SERVICE"
delete_schedule_if_exists "$SCHEDULE_STOP_INTEGRATION"

echo "停止完了"
