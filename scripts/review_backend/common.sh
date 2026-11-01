#!/bin/bash
# 呼出元が REGION を設定してから利用する共通の前提検証とschedule削除。
require_value() {
  if [[ -z "$2" || "$2" == "None" || "$2" == "null" ]]; then
    echo "ERROR: $1 を取得できませんでした。" >&2
    return 1
  fi
}

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
