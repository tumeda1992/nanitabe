#!/bin/bash
# review 環境（backend on ECS）を起動する。
#
# 何を行うか（design.md の workflow を参照）:
#   1. 既に desired_count=1 の場合も、private経路と自動停止 schedule を再整合する
#   2. desired_count を 1 にし、task が RUNNING になるまで待つ
#   3. Cloud Map のhealthy登録とVPC linkのAVAILABLEを確認する
#   4. REVIEW_BACKEND_AUTO_STOP_MINUTES（既定 30）後に自動停止する one-time schedule を作る
#   5. 途中で失敗・割込みがあれば、desired_count の停止を試みてエラー終了する
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
AUTO_STOP_MINUTES="${REVIEW_BACKEND_AUTO_STOP_MINUTES:-30}"
DOMAIN="review-backend-nanitabe.${ROUTE53_HOSTZONE_NAME}"
SCHEDULE_STOP_SERVICE="nanitabe-back_review_auto_stop_service"
SCHEDULE_STOP_INTEGRATION="nanitabe-back_review_auto_stop_integration"

rollback_required=0
api_id=""
vpc_link_id=""
DISCOVERY_NAMESPACE="${CLUSTER}.internal"
DISCOVERY_SERVICE="backend"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

rollback_on_exit() {
  status=$?
  trap - EXIT INT TERM
  if (( status != 0 && rollback_required == 1 )); then
    set +e
    echo "ERROR: 起動を中断しました。rollbackで停止を試みます。" >&2
    if ! aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 0 --region "$REGION" >/dev/null; then
      echo "ERROR: ECS の停止に失敗しました。状態確認と停止が必要です。" >&2
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

vpc_link_id=$(aws apigatewayv2 get-vpc-links --region "$REGION" \
  --query "Items[?Name=='${API_NAME}'].VpcLinkId | [0]" --output text)
require_value "VPC link ID" "$vpc_link_id"

discovery_arn=$(aws apigatewayv2 get-integrations --api-id "$api_id" --region "$REGION" \
  --query "Items[?ConnectionType=='VPC_LINK' && ConnectionId=='${vpc_link_id}'].IntegrationUri | [0]" --output text)
require_value "private integration" "$discovery_arn"
if [[ "$discovery_arn" != arn:aws:servicediscovery:*:service/* ]]; then
  echo "ERROR: private integration の適用を先に完了してください。" >&2
  exit 1
fi

scheduler_role_arn=$(aws iam get-role --role-name "$SCHEDULER_ROLE_NAME" --query 'Role.Arn' --output text)

require_value "scheduler role" "$scheduler_role_arn"

target_stop_service=$(jq -n \
  --arg arn "arn:aws:scheduler:::aws-sdk:ecs:updateService" \
  --arg role "$scheduler_role_arn" \
  --arg input "$(jq -n --arg cluster "$CLUSTER" --arg service "$SERVICE" '{Cluster:$cluster, Service:$service, DesiredCount:0}')" \
  '{Arn:$arn, RoleArn:$role, Input:$input}')

# 旧public-IP方式の停止scheduleも、固定ARNを書き換えないように除去する。
delete_schedule_if_exists "$SCHEDULE_STOP_SERVICE"
delete_schedule_if_exists "$SCHEDULE_STOP_INTEGRATION"

# 2. desired_count を 1 にし、RUNNING になるまで待つ
echo "desired_count を 1 にします..."
rollback_required=1
if [ "$desired_count" != "1" ]; then
  aws ecs update-service --cluster "$CLUSTER" --service "$SERVICE" --desired-count 1 --region "$REGION" >/dev/null
fi

echo "task が RUNNING になるのを待ちます..."
aws ecs wait services-stable --cluster "$CLUSTER" --services "$SERVICE" --region "$REGION"

# 3. Cloud Mapのhealthy登録とVPC linkの再有効化を待つ。
# INACTIVEからのENI再作成は、APIへの実requestを契機に開始される。
private_ready=0
for (( attempt=1; attempt<=30; attempt++ )); do
  healthy_instances=$(aws servicediscovery discover-instances \
    --namespace-name "$DISCOVERY_NAMESPACE" --service-name "$DISCOVERY_SERVICE" \
    --health-status HEALTHY --region "$REGION" --query 'length(Instances)' --output text)
  if [[ ! "$healthy_instances" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Cloud Map のhealthy登録を確認できませんでした。" >&2
    exit 1
  fi

  http_ready=0
  if readiness_response=$(curl --silent --show-error --connect-timeout 5 --max-time 10 \
    --request POST --header 'Content-Type: application/json' \
    --data '{"query":"query ReviewBackendReadiness { __typename }"}' \
    --write-out $'\n%{http_code}' "https://${DOMAIN}/graphql"); then
    http_status="${readiness_response##*$'\n'}"
    readiness_body="${readiness_response%$'\n'*}"
    # Gateway自身の404やHTMLをbackendの準備完了と取り違えない。
    if [[ "$http_status" == "200" ]] && printf '%s' "$readiness_body" | jq -e '.data.__typename == "Query" and .errors == null' >/dev/null 2>&1; then
      http_ready=1
    fi
  else
    echo "private経路のrequestを再試行します。" >&2
  fi
  vpc_link_status=$(aws apigatewayv2 get-vpc-link --vpc-link-id "$vpc_link_id" \
    --region "$REGION" --query 'VpcLinkStatus' --output text)
  require_value "VPC link status" "$vpc_link_status"
  case "$vpc_link_status" in
    AVAILABLE|PENDING|INACTIVE) ;;
    *) echo "ERROR: VPC link を利用できません。" >&2; exit 1 ;;
  esac
  if [[ "$vpc_link_status" == "AVAILABLE" ]] && (( healthy_instances > 0 && http_ready == 1 )); then
    private_ready=1
    break
  fi
  if (( attempt < 30 )); then sleep 10; fi
done
if (( private_ready != 1 )); then
  echo "ERROR: private経路の準備が期限内に完了しませんでした。" >&2
  exit 1
fi

run_at=$(date -u -v"+${AUTO_STOP_MINUTES}M" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null \
  || date -u -d "+${AUTO_STOP_MINUTES} minutes" +"%Y-%m-%dT%H:%M:%S")

require_value "schedule date" "$run_at"

# 4. 自動停止用の one-time schedule を作る（既存の同名 schedule は作り直す）
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

rollback_required=0
echo "起動完了"
echo "URL: https://${DOMAIN}/graphql"
echo "自動停止予定時刻 (UTC): ${run_at}"
