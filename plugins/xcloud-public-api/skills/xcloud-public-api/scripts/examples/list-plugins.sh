#!/usr/bin/env bash
# Example: list plugins on a site, filtered to those with available updates.
#
# Usage:
#   ./list-plugins.sh <site_uuid>
#   ./list-plugins.sh <site_uuid> active   # only active plugins

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCLOUD="${SCRIPT_DIR}/../xcloud.sh"

SITE_UUID="${1:?usage: list-plugins.sh <site_uuid> [status]}"
STATUS="${2:-all}"

QUERY="update_status=available&per_page=100"
if [[ "${STATUS}" != "all" ]]; then
  QUERY="${QUERY}&status=${STATUS}"
fi

"${XCLOUD}" GET "/sites/${SITE_UUID}/wordpress/plugins?${QUERY}" \
  | jq -r '.data.items[] | "\(.name)\t\(.current_version) -> \(.available_version)\t(\(.status))"'
