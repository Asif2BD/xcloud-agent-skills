#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud-wordpress. No mutations.
# Usage: XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh   (site must be WordPress)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set (a WordPress site)}"
PASS=0; FAIL=0
check(){ local l="$1" p="$2"
  if ! o=$("${XC}" GET "${p}" 2>&1); then echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); return; fi
  if ! echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${l} (${p}): bad envelope" >&2; FAIL=$((FAIL+1)); return; fi
  echo "PASS ${l}"; PASS=$((PASS+1)); }
S="${XCLOUD_TEST_SITE_UUID}"
check "wp plugins"        "/sites/${S}/wordpress/plugins"
check "wp themes"         "/sites/${S}/wordpress/themes"
check "wp updates"        "/sites/${S}/wordpress/updates"
check "wp status"         "/sites/${S}/wordpress/status"
check "vuln count"        "/sites/${S}/vulnerabilities/count"
check "vuln list"         "/sites/${S}/vulnerabilities"
check "pagespeed latest"  "/sites/${S}/pagespeed"
echo; echo "Smoke: ${PASS} passed, ${FAIL} failed"; (( FAIL == 0 ))
