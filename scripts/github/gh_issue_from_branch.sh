#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Role: Resolve GitHub Issue info from the current git branch name.
#
# Purpose (for humans & AI):
# - Deterministic utility (no AI reasoning required).
# - Input: current git branch name
# - Output: Issue metadata in JSON to stdout
#
# Contract:
# - Expected branch format: feature-<issue_id> (e.g., feature-176)
# - If branch format is invalid OR issue does not exist, exit non-zero and write
#   a single-line error message to stderr (stdout MUST be empty in error cases).
#
# Output JSON schema:
#   {
#     "branch": "feature-176",
#     "issue_id": 176,
#     "title": "Issue title"
#   }
#
# Requirements:
# - git
# - gh (authenticated to the repo)
#
# Usage:
#   scripts/gh_issue_from_branch.sh
# -----------------------------------------------------------------------------

branch="$(git branch --show-current 2>/dev/null || true)"
if [[ -z "${branch}" ]]; then
  echo "ERROR: failed to get current branch name" >&2
  exit 1
fi

if [[ ! "${branch}" =~ ^feature-([0-9]+)$ ]]; then
  echo "ERROR: invalid branch format: ${branch} (expected: feature-<id>)" >&2
  exit 1
fi

issue_id="${BASH_REMATCH[1]}"

# Fetch title; if not found or unauthorized, treat as error.
issue_title="$(gh issue view "${issue_id}" --json title --jq .title 2>/dev/null || true)"
if [[ -z "${issue_title}" ]]; then
  echo "ERROR: issue not found or not accessible: #${issue_id}" >&2
  exit 1
fi

# Emit JSON (use python for proper escaping)
python3 - <<PY
import json
print(json.dumps({
  "issue_id": int("${issue_id}"),
  "issue_title": "${issue_title}",
  "branch": "${branch}",
}, ensure_ascii=False))
PY
