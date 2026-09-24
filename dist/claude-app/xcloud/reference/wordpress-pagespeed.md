# PageSpeed Insights

`XC="scripts/xcloud.sh"` · scope `read:sites` / `write:sites`,
plus the `site:manage-update` team permission.

| Operation | Method + path |
|---|---|
| Latest completed run (mobile + desktop) | `GET /sites/{uuid}/pagespeed` |
| History (newest first, `strategy=mobile\|desktop`) | `GET /sites/{uuid}/pagespeed/history` |
| Trigger scan | `POST /sites/{uuid}/pagespeed/scan` |
| One scan (poll this) | `GET /sites/{uuid}/pagespeed/scans/{scan_uuid}` |

```bash
SITE_UUID='replace-me'
SCAN=$("$XC" POST "/sites/$SITE_UUID/pagespeed/scan" | jq -r '.data.scan_uuid')   # 202, async
"$XC" GET "/sites/$SITE_UUID/pagespeed/scans/$SCAN" | jq '.data'   # poll until both strategies finish
"$XC" GET "/sites/$SITE_UUID/pagespeed" | jq '.data'
"$XC" GET "/sites/$SITE_UUID/pagespeed/history?strategy=mobile" | jq '(.data.items // .data) | .[0:10]'
```

- One scan runs both strategies; it is complete only when the mobile **and**
  desktop results for that `scan_uuid` are in. `409` means a scan for this
  site is still pending or running — poll it instead of starting another (a
  scan stuck for over an hour is marked failed).
- "Compare with previous scans" → latest run against `history` for the same
  strategy; report the score change and the metric that moved most.
- Applies to any site, not only WordPress (owned here by convention).
