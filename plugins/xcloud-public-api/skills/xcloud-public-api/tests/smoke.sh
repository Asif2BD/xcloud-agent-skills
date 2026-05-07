#!/usr/bin/env bash
# smoke.sh — hits every Slice A PR1 endpoint against the configured environment.
#
# Pass / fail criteria:
#   - 200 status code
#   - response body is valid JSON
#   - response.success == true
#   - response.data is present
#
# Usage:
#   XCLOUD_API_TOKEN=... XCLOUD_TEST_SITE_UUID=... ./smoke.sh
#
# Optional:
#   XCLOUD_API_BASE_URL  (default https://app.xcloud.host)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCLOUD="${SCRIPT_DIR}/../scripts/xcloud.sh"

: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
: "${XCLOUD_TEST_SITE_UUID:?XCLOUD_TEST_SITE_UUID must be set (a real WordPress site UUID)}"

PASS=0
FAIL=0

assert_endpoint() {
  local label="$1"
  local path="$2"

  if ! out=$("${XCLOUD}" GET "${path}" 2>&1); then
    echo "FAIL ${label} (${path}): ${out}" >&2
    FAIL=$((FAIL + 1))
    return
  fi

  if ! echo "${out}" | jq -e '.success == true and .data != null' > /dev/null; then
    echo "FAIL ${label} (${path}): bad envelope" >&2
    echo "${out}" >&2
    FAIL=$((FAIL + 1))
    return
  fi

  echo "PASS ${label}"
  PASS=$((PASS + 1))
}

# Slice A PR1 — WP info reads
assert_endpoint "WP plugins"  "/sites/${XCLOUD_TEST_SITE_UUID}/wordpress/plugins"
assert_endpoint "WP themes"   "/sites/${XCLOUD_TEST_SITE_UUID}/wordpress/themes"
assert_endpoint "WP updates"  "/sites/${XCLOUD_TEST_SITE_UUID}/wordpress/updates"
assert_endpoint "WP status"   "/sites/${XCLOUD_TEST_SITE_UUID}/wordpress/status"

echo
echo "Smoke: ${PASS} passed, ${FAIL} failed"

if (( FAIL > 0 )); then
  exit 1
fi
