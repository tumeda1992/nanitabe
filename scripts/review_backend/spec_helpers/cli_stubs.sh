# テスト用shellだけがBASH_ENVから読む。AWS/HTTPへの通信は行わない。
stub_arg() {
  local key="$1"
  shift
  while (( $# > 1 )); do
    if [[ "$1" == "$key" ]]; then printf '%s' "$2"; return; fi
    shift
  done
}
stub_fail() {
  if [[ "${FAIL_AT:-}" == "$1" ]]; then echo "test failure: $1" >&2; exit 42; fi
}
stub_output() {
  stub_fail "$1"
  if [[ "${EMPTY_AT:-}" == "$1" ]]; then echo None; else printf '%s\n' "$2"; fi
}
aws() {
  printf '%s\0' "$@" >> "$TEST_DIRECTORY/calls"
  printf '\036' >> "$TEST_DIRECTORY/calls"
  local desired name count status
  case "$1 $2" in
    'ecs describe-services') stub_output describe "$(cat "$TEST_DIRECTORY/desired")" ;;
    'ecs update-service')
      desired=$(stub_arg --desired-count "$@")
      if [[ "$desired" == 0 && "${CLEANUP_FAIL:-}" == service ]]; then echo 'cleanup service denied' >&2; return 99; fi
      printf '%s' "$desired" > "$TEST_DIRECTORY/desired"
      if [[ "$desired" == 1 ]]; then stub_fail start; fi ;;
    'ecs wait')
      if [[ -n "${SIGNAL:-}" ]]; then kill -s "$SIGNAL" "$$"; fi
      stub_fail wait ;;
    'apigatewayv2 get-apis') stub_output api example-api ;;
    'apigatewayv2 get-vpc-links') stub_output vpc-link-id example-link ;;
    'apigatewayv2 get-integrations')
      if [[ -n "${PUBLIC_INTEGRATION:-}" ]]; then echo 'http://203.0.113.10'; else
        stub_output private-integration 'arn:aws:servicediscovery:ap-northeast-1:000000000000:service/srv-example'; fi ;;
    'apigatewayv2 get-vpc-link')
      count=$(cat "$TEST_DIRECTORY/vpc_reads"); count=$((count + 1)); echo "$count" > "$TEST_DIRECTORY/vpc_reads"
      status="${VPC_STATUS:-AVAILABLE}"
      if (( count <= ${INACTIVE_CYCLES:-0} )); then status=INACTIVE; fi
      stub_output vpc-link-status "$status" ;;
    'servicediscovery discover-instances')
      count=$(cat "$TEST_DIRECTORY/discovery_reads"); count=$((count + 1)); echo "$count" > "$TEST_DIRECTORY/discovery_reads"
      status="${HEALTHY_COUNT:-1}"
      if (( count <= ${UNHEALTHY_CYCLES:-0} )); then status=0; fi
      stub_output discovery "$status" ;;
    'iam get-role') stub_output role 'arn:aws:iam::000000000000:role/example' ;;
    'scheduler delete-schedule')
      stub_fail delete
      name=$(stub_arg --name "$@")
      if grep -Fxq "$name" "$TEST_DIRECTORY/schedules"; then
        grep -Fxv "$name" "$TEST_DIRECTORY/schedules" > "$TEST_DIRECTORY/remaining" || true
        mv "$TEST_DIRECTORY/remaining" "$TEST_DIRECTORY/schedules"
      else echo 'An error occurred (ResourceNotFoundException): absent' >&2; return 254; fi ;;
    'scheduler create-schedule')
      stub_fail schedule-service
      stub_arg --name "$@" >> "$TEST_DIRECTORY/schedules"
      printf '\n' >> "$TEST_DIRECTORY/schedules" ;;
    *) echo "unexpected AWS operation $1 $2" >&2; exit 94 ;;
  esac
}
date() { stub_fail date; echo '2026-11-02T00:30:00'; }
jq() { stub_fail jq; command "$TEST_JQ" "$@"; }
curl() {
  local count body
  printf '%s\0' curl "$@" >> "$TEST_DIRECTORY/calls"
  printf '\036' >> "$TEST_DIRECTORY/calls"
  count=$(cat "$TEST_DIRECTORY/curl_calls"); count=$((count + 1)); echo "$count" > "$TEST_DIRECTORY/curl_calls"
  if [[ "${FAIL_AT:-}" == curl ]]; then return 42; fi
  if [[ "${CURL_BODY+x}" == x ]]; then body="$CURL_BODY"; else body='{"data":{"__typename":"Query"}}'; fi
  if [[ -z "$(stub_arg --output "$@")" ]]; then printf '%s\n' "$body"; fi
  printf '%s' "${CURL_STATUS:-200}"
}
sleep() { :; }
