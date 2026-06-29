#!/usr/bin/env bash
# smoke.sh — read-only checks for the xcloud:ssl skill against the configured env.
#
# Pass criteria per endpoint: HTTP 2xx, valid JSON, .success == true, .data present.
# Only READ endpoints are exercised (no certs are installed/renewed/deleted).
#
# Usage:
#   XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
#   # local:
#   XCLOUD_API_BASE_URL=http://xcloud.test XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
#
# Optional:
#   XCLOUD_TEST_CERT_UUID  — if set, also checks the by-UUID cert endpoints.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Shared wrapper lives at the plugin root (../../../../scripts from this skill's tests/).
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"

: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set (a real site UUID)}"

PASS=0
FAIL=0
SKIP=0

check() {
  local label="$1" path="$2"
  if ! out=$("${XC}" GET "${path}" 2>&1); then
    echo "FAIL ${label} (${path}): ${out}" >&2; FAIL=$((FAIL + 1)); return
  fi
  if ! echo "${out}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "FAIL ${label} (${path}): bad envelope" >&2; echo "${out}" >&2; FAIL=$((FAIL + 1)); return
  fi
  echo "PASS ${label}"; PASS=$((PASS + 1))
}

# check_opt: a site with no SSL configured yet may 404 (or 422 "not supported");
# treat that as SKIP rather than FAIL.
check_opt() {
  local label="$1" path="$2" out rc code
  out=$("${XC}" GET "${path}" 2>&1) && rc=0 || rc=$?
  if (( rc == 0 )) && echo "${out}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "PASS ${label}"; PASS=$((PASS + 1)); return
  fi
  code=$(printf '%s\n' "${out}" | sed -n 's/.*HTTP \([0-9][0-9][0-9]\).*/\1/p' | tail -n1)
  if [[ "${code}" == "404" ]] || { [[ "${code}" == "422" ]] && printf '%s' "${out}" | grep -qiE 'not supported|not available|unsupported|does not support|not applicable'; }; then
    echo "SKIP ${label} (optional: HTTP ${code:-?})"; SKIP=$((SKIP + 1)); return
  fi
  echo "FAIL ${label} (${path}): ${out}" >&2; FAIL=$((FAIL + 1))
}

check_opt "site SSL info"     "/sites/${XCLOUD_TEST_SITE_UUID}/ssl"
check     "site certificates" "/sites/${XCLOUD_TEST_SITE_UUID}/ssl-certificates"

if [[ -n "${XCLOUD_TEST_CERT_UUID:-}" ]]; then
  check "cert by uuid"   "/ssl-certificates/${XCLOUD_TEST_CERT_UUID}"
  check "cert status"    "/ssl-certificates/${XCLOUD_TEST_CERT_UUID}/status"
fi

echo
echo "Smoke: ${PASS} passed, ${SKIP} skipped, ${FAIL} failed"
(( FAIL == 0 ))
