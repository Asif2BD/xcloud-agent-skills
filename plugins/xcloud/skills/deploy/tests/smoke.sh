#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:deploy through the bundled GET-only
# wrapper. Repository detection is a POST, so it is MCP-only and not covered
# here; nothing in this suite creates, retries or installs.
# Usage: XCLOUD_API_TOKEN=... [XCLOUD_TEST_SERVER_UUID=...] ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
PASS=0; FAIL=0
verdict(){ local l="$1" p="$2" o="$3"
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
check(){ local l="$1" p="$2" o
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  verdict "${l}" "${p}" "${o}"; }
check "one-click catalog" "/oneclick-apps?per_page=1"
check "app requirements"  "/catalog/apps"
check "git integrations"  "/integrations/git"
# The wrapper must refuse a POST before any request (detection runs on MCP).
if "${XC}" POST /git/detect '{}' >/dev/null 2>&1; then
  echo "FAIL wrapper accepted a POST" >&2; FAIL=$((FAIL+1))
else
  echo "PASS wrapper refuses POST (detection is MCP-only)"; PASS=$((PASS+1))
fi
if [[ -n "${XCLOUD_TEST_SERVER_UUID:-}" ]]; then
  S="${XCLOUD_TEST_SERVER_UUID}"
  check "staging hostname" "/servers/${S}/staging-hostname?label=smoke-check"
  check "deploy keys"      "/servers/${S}/git/deploy-keys"
fi
echo; echo "Smoke: ${PASS} passed, ${FAIL} failed"; (( FAIL == 0 ))
