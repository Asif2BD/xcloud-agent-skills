#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:account. No mutations.
# Usage: XCLOUD_API_TOKEN=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
PASS=0; FAIL=0
check(){ local l="$1" p="$2"
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
# /health is the one endpoint that does NOT use the {success,data} envelope.
if o=$("${XC}" GET "/health" 2>&1) && echo "${o}" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  echo "PASS health"; PASS=$((PASS+1))
else
  echo "FAIL health: ${o}" >&2; FAIL=$((FAIL+1))
fi
check "current user" "/user"
check "blueprints"   "/blueprints?per_page=1"
check "cloudflare"   "/integrations/cloudflare"
echo; echo "Smoke: ${PASS} passed, ${FAIL} failed"; (( FAIL == 0 ))
