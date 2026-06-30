# Site vulnerabilities

`XC="${CLAUDE_PLUGIN_ROOT}/scripts/xcloud.sh"` · scope `read:sites` / `write:sites`.

| Operation | Method + path |
|---|---|
| List site vulnerabilities | `GET /sites/{uuid}/vulnerabilities` |
| Count by severity | `GET /sites/{uuid}/vulnerabilities/count` |
| Trigger rescan | `POST /sites/{uuid}/vulnerability-scan` |
| Ignore a finding | `POST /sites/{uuid}/vulnerabilities/{vulnerabilityUuid}/ignore` |
| Un-ignore a finding | `DELETE /sites/{uuid}/vulnerabilities/{vulnerabilityUuid}/ignore` |
| Team-wide rollup | `GET /vulnerabilities?site={uuid}` |

```bash
SITE_UUID='replace-me'
"$XC" POST "/sites/$SITE_UUID/vulnerability-scan" | jq '.message'        # async
"$XC" GET  "/sites/$SITE_UUID/vulnerabilities/count" | jq '.data'        # {critical,high,medium,low}
"$XC" GET  "/sites/$SITE_UUID/vulnerabilities" \
  | jq '(.data.items // .data) | map({uuid, slug, severity, source, title})'
```

Ignore / un-ignore a specific finding:

```bash
VULN_UUID='replace-me'
"$XC" POST   "/sites/$SITE_UUID/vulnerabilities/$VULN_UUID/ignore" '{"reason":"false positive"}' | jq '.message'
"$XC" DELETE "/sites/$SITE_UUID/vulnerabilities/$VULN_UUID/ignore" | jq '.message'
```

Team-wide rollup (the top-level endpoint **requires** a `site` query param):

```bash
"$XC" GET "/vulnerabilities?site=$SITE_UUID" | jq '.data'
```

- Scans are async — poll `count` or `GET /sites/{uuid}/events` after triggering.
- Findings come from sources like Patchstack/Wordfence; treat `severity` as the
  triage key.
