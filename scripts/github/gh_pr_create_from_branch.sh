#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Resolve script directory (robust against invocation location)
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ISSUE_SCRIPT="${SCRIPT_DIR}/gh_issue_from_branch.sh"

if [[ ! -x "${ISSUE_SCRIPT}" ]]; then
  echo "ERROR: dependency script not found or not executable: ${ISSUE_SCRIPT}" >&2
  exit 1
fi

info_json="$("${ISSUE_SCRIPT}")"

issue_id="$(echo "${info_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["issue_id"])')"
issue_title="$(echo "${info_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["issue_title"])')"
branch="$(echo "${info_json}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["branch"])')"

pr_url="$(gh pr create --title "${issue_title}" --base "main" --head "${branch}" --body "Closes #${issue_id}")"

if [[ -z "${pr_url}" ]]; then
  pr_url="$(gh pr view --json url --jq .url)"
fi

echo "${pr_url}"
