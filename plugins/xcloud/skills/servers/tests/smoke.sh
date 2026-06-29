#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:servers. No mutations.
# Usage: XCLOUD_API_TOKEN=... XCLOUD_TEST_SERVER_UUID=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SERVER_UUID:?XCLOUD_TEST_SERVER_UUID must be set}"
PASS=0; FAIL=0; SKIP=0
check(){ local l="$1" p="$2"
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
# check_opt: like check, but optional sub-resources that a server/site type may not
# support (404, or 422 "not supported") count as SKIP rather than FAIL.
check_opt(){ local l="$1" p="$2" o rc code
  o=$("${XC}" GET "${p}" 2>&1) && rc=0 || rc=$?
  if (( rc == 0 )) && echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "PASS ${l}"; PASS=$((PASS+1)); return; fi
  code=$(printf '%s\n' "${o}" | sed -n 's/.*HTTP \([0-9][0-9][0-9]\).*/\1/p' | tail -n1)
  if [[ "${code}" == "404" ]] || { [[ "${code}" == "422" ]] && printf '%s' "${o}" | grep -qiE 'not supported|not available|unsupported|does not support|not applicable'; }; then
    echo "SKIP ${l} (optional: HTTP ${code:-?})"; SKIP=$((SKIP+1)); return; fi
  echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); }
S="${XCLOUD_TEST_SERVER_UUID}"
check     "list servers"   "/servers?per_page=1"
check     "get server"     "/servers/${S}"
check     "server sites"   "/servers/${S}/sites"
check     "php versions"   "/servers/${S}/php-versions"
check_opt "databases"      "/servers/${S}/databases"
check     "firewall rules" "/servers/${S}/firewall-rules"
check     "sudo users"     "/servers/${S}/sudo-users"
check     "tasks"          "/servers/${S}/tasks"
echo; echo "Smoke: ${PASS} passed, ${SKIP} skipped, ${FAIL} failed"; (( FAIL == 0 ))
