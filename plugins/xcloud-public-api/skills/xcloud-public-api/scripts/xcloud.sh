#!/usr/bin/env bash
# xcloud.sh — thin curl wrapper for the xCloud Public API.
#
# Usage:
#   ./xcloud.sh GET  /sites
#   ./xcloud.sh GET  '/sites/abc-123/wordpress/plugins?status=active'
#   ./xcloud.sh POST /sites/abc-123/backup '{"label":"pre-update"}'
#
# Reads:
#   XCLOUD_API_TOKEN     (required) Sanctum personal access token
#   XCLOUD_API_BASE_URL  (default https://app.xcloud.host) — override for white-label
#   XCLOUD_VERBOSE       (optional) set to 1 for verbose curl output
#
# Output: response body to stdout. Exit code 0 on 2xx, non-zero on 4xx/5xx.

set -euo pipefail

if [[ -z "${XCLOUD_API_TOKEN:-}" ]]; then
  echo "error: XCLOUD_API_TOKEN is not set. See agent-skills/xcloud-public-api/reference/auth.md" >&2
  exit 64
fi

BASE_URL="${XCLOUD_API_BASE_URL:-https://app.xcloud.host}"
METHOD="${1:?usage: xcloud.sh <METHOD> <PATH> [JSON_BODY]}"
RAW_PATH="${2:?usage: xcloud.sh <METHOD> <PATH> [JSON_BODY]}"
BODY="${3:-}"

# Normalize path: ensure it starts with /api/v1
if [[ "${RAW_PATH}" == /api/v1/* ]]; then
  PATH_PART="${RAW_PATH}"
elif [[ "${RAW_PATH}" == /* ]]; then
  PATH_PART="/api/v1${RAW_PATH}"
else
  PATH_PART="/api/v1/${RAW_PATH}"
fi

URL="${BASE_URL}${PATH_PART}"

CURL_OPTS=(
  -sS
  -X "${METHOD}"
  -H "Authorization: Bearer ${XCLOUD_API_TOKEN}"
  -H "Accept: application/json"
  -H "Content-Type: application/json"
  -w '\n%{http_code}'
)

if [[ "${XCLOUD_VERBOSE:-0}" == "1" ]]; then
  CURL_OPTS+=(-v)
fi

if [[ -n "${BODY}" ]]; then
  CURL_OPTS+=(--data-raw "${BODY}")
fi

RESPONSE=$(curl "${CURL_OPTS[@]}" "${URL}")
HTTP_CODE=$(printf '%s' "${RESPONSE}" | tail -n1)
BODY_OUT=$(printf '%s' "${RESPONSE}" | sed '$d')

printf '%s\n' "${BODY_OUT}"

if (( HTTP_CODE >= 400 )); then
  echo "" >&2
  echo "HTTP ${HTTP_CODE} from ${METHOD} ${PATH_PART}" >&2
  exit 1
fi
