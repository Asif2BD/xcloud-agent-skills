#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:performance. No mutations: no
# PageSpeed scan, no cache purge, no PHP change.
# Monitoring history is a paid feature and monitoring/PageSpeed reads need team
# permissions, so a 403 on those counts as SKIP rather than FAIL.
# Usage: XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set}"
PASS=0; FAIL=0; SKIP=0
check(){ local l="$1" p="$2" o
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
# check_opt: 403 (plan limit or team permission), 404, or 422 "not supported"
# count as SKIP.
check_opt(){ local l="$1" p="$2" o rc code
  o=$("${XC}" GET "${p}" 2>&1) && rc=0 || rc=$?
  if (( rc == 0 )) && echo "${o}" | jq -e '.success == true' >/dev/null 2>&1; then
    echo "PASS ${l}"; PASS=$((PASS+1)); return; fi
  code=$(printf '%s\n' "${o}" | sed -n 's/.*HTTP \([0-9][0-9][0-9]\).*/\1/p' | tail -n1)
  if [[ "${code}" == "403" || "${code}" == "404" ]] || { [[ "${code}" == "422" ]] && printf '%s' "${o}" | grep -qiE 'not supported|not available|unsupported|does not support|not applicable|not a wordpress'; }; then
    echo "SKIP ${l} (optional: HTTP ${code:-?})"; SKIP=$((SKIP+1)); return; fi
  echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); }
S="${XCLOUD_TEST_SITE_UUID}"
check_opt "site monitoring"         "/sites/${S}/monitoring"
check_opt "site monitoring history" "/sites/${S}/monitoring/history?range=24h"
check_opt "cache settings"          "/sites/${S}/cache/settings"
check_opt "pagespeed latest"        "/sites/${S}/pagespeed"
if server=$("${XC}" GET "/sites/${S}" 2>/dev/null | jq -er '.data.server_uuid'); then
  check     "server monitoring"         "/servers/${server}/monitoring"
  check_opt "server monitoring history" "/servers/${server}/monitoring/history?range=24h"
  check     "server services"           "/servers/${server}/services"
else
  echo "FAIL server uuid: could not read .data.server_uuid from /sites/${S}" >&2; FAIL=$((FAIL+1))
fi
echo; echo "Smoke: ${PASS} passed, ${SKIP} skipped, ${FAIL} failed"; (( FAIL == 0 ))
