#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud-sites. No mutations.
# Usage: XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set}"
PASS=0; FAIL=0
check(){ local l="$1" p="$2"
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
S="${XCLOUD_TEST_SITE_UUID}"
check "list sites"     "/sites?per_page=1"
check "get site"       "/sites/${S}"
check "status"         "/sites/${S}/status"
check "events"         "/sites/${S}/events"
check "backups"        "/sites/${S}/backups"
check "domain"         "/sites/${S}/domain"
check "ssh config"     "/sites/${S}/ssh"
check "cache settings" "/sites/${S}/cache/settings"
echo; echo "Smoke: ${PASS} passed, ${FAIL} failed"; (( FAIL == 0 ))
