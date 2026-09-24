#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:troubleshoot. No mutations: no
# WP_DEBUG toggle, no sudo user, no rescue, no purge.
# Usage: XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set}"
PASS=0; FAIL=0; SKIP=0
check(){ local l="$1" p="$2" o
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
# check_opt: reads a site type may not support (404, or 422 "not supported" —
# e.g. WordPress status on a non-WordPress site) count as SKIP, not FAIL.
check_opt(){ local l="$1" p="$2" o rc code
  o=$("${XC}" GET "${p}" 2>&1) && rc=0 || rc=$?
  if (( rc == 0 )) && echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "PASS ${l}"; PASS=$((PASS+1)); return; fi
  code=$(printf '%s\n' "${o}" | sed -n 's/.*HTTP \([0-9][0-9][0-9]\).*/\1/p' | tail -n1)
  if [[ "${code}" == "404" ]] || { [[ "${code}" == "422" ]] && printf '%s' "${o}" | grep -qiE 'not supported|not available|unsupported|does not support|not applicable|not a wordpress'; }; then
    echo "SKIP ${l} (optional: HTTP ${code:-?})"; SKIP=$((SKIP+1)); return; fi
  echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); }
S="${XCLOUD_TEST_SITE_UUID}"
check     "status"            "/sites/${S}/status"
check     "events"            "/sites/${S}/events?per_page=5"
check     "deployment logs"   "/sites/${S}/deployment-logs?per_page=5"
check_opt "nginx logs"        "/sites/${S}/access-logs?type=nginx&limit=5"
check_opt "wordpress status"  "/sites/${S}/wordpress/status"
if server=$("${XC}" GET "/sites/${S}" 2>/dev/null | jq -er '.data.server_uuid'); then
  check   "server services"   "/servers/${server}/services"
else
  echo "FAIL server uuid: could not read .data.server_uuid from /sites/${S}" >&2; FAIL=$((FAIL+1))
fi
echo; echo "Smoke: ${PASS} passed, ${SKIP} skipped, ${FAIL} failed"; (( FAIL == 0 ))
