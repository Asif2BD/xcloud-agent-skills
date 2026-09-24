#!/usr/bin/env bash
# smoke.sh — read-only checks for xcloud:billing. No purchases, no payments.
# Billing and add-on reads need read:billing / read:addons; a token without
# those scopes answers 403, which counts as SKIP rather than FAIL.
# Usage: XCLOUD_API_TOKEN=... ./smoke.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XC="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}/scripts/xcloud.sh"
: "${XCLOUD_API_TOKEN:?XCLOUD_API_TOKEN must be set}"
PASS=0; FAIL=0; SKIP=0
check_scoped(){ local l="$1" p="$2" o rc code
  o=$("${XC}" GET "${p}" 2>&1) && rc=0 || rc=$?
  if (( rc == 0 )) && echo "${o}" | jq -e '.success == true and .data != null' >/dev/null 2>&1; then
    echo "PASS ${l}"; PASS=$((PASS+1)); return; fi
  code=$(printf '%s\n' "${o}" | sed -n 's/.*HTTP \([0-9][0-9][0-9]\).*/\1/p' | tail -n1)
  if [[ "${code}" == "403" ]]; then
    echo "SKIP ${l} (token lacks the scope: HTTP 403)"; SKIP=$((SKIP+1)); return; fi
  echo "FAIL ${l} (${p}): ${o}" >&2; FAIL=$((FAIL+1)); }
check_scoped "plan"               "/billing/plan"
check_scoped "overview"           "/billing/overview"
check_scoped "invoices"           "/billing/invoices?per_page=1"
check_scoped "subscriptions"      "/billing/subscriptions?per_page=1"
check_scoped "public pricing"     "/catalog/pricing"
check_scoped "server plans"       "/servers/plans"
check_scoped "mailbox plans"      "/addons/mailbox/plans"
check_scoped "mail delivery plans" "/addons/mail-delivery/plans"
echo; echo "Smoke: ${PASS} passed, ${SKIP} skipped, ${FAIL} failed"; (( FAIL == 0 ))
