#!/usr/bin/env bash
# xcloud.sh — thin curl wrapper for the xCloud Public API.
#
# Shared by every xcloud-* domain skill. Skills invoke it via
# scripts/xcloud.sh — one copy, no per-skill duplication.
#
# Usage:
#   ./xcloud.sh GET  /sites
#   ./xcloud.sh GET  '/sites/abc-123/ssl'
#   ./xcloud.sh POST /sites/abc-123/ssl/renew '{"force":true}'
#
# Reads:
#   XCLOUD_API_TOKEN     (required) Sanctum personal access token
#   XCLOUD_API_BASE_URL  (default https://app.xcloud.host) — set to
#                        http://xcloud.test for local, or a white-label host
#   XCLOUD_VERBOSE       (optional) set to 1 for verbose curl output
#
# Output: response body to stdout. Exit code 0 on 2xx, non-zero on 4xx/5xx.

set -euo pipefail

if [[ -z "${XCLOUD_API_TOKEN:-}" ]]; then
  cat >&2 <<'EOF'
error: XCLOUD_API_TOKEN is not set.

Step 1 — Create an API token in xCloud:
  xCloud dashboard -> Profile -> API Tokens -> Generate New Token
  -> choose the scopes you need (e.g. read:servers) -> copy it (shown only once).

Step 2 — Store it persistently for Claude Code:
  a. Open  ~/.claude/settings.json   (e.g.  nano ~/.claude/settings.json )
  b. Add an "env" block with your token:
       {
         "env": {
           "XCLOUD_API_TOKEN": "your-token-here",
           "XCLOUD_API_BASE_URL": "https://app.xcloud.host"
         }
       }
  c. Restart Claude Code (quit + reopen) so it loads.

Do NOT use '! export ...' in the prompt — it runs in a throwaway subshell and
will not persist to the next call. See reference/auth.md for the full guide
(and the claude.ai-app alternative).
EOF
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
