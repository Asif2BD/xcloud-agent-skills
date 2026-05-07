# Error Handling

All xCloud Public API errors follow the same envelope:

```json
{
  "success": false,
  "message": "Human-readable summary",
  "errors": { "field_name": ["validation message", "..."] }
}
```

## Status codes

| Code | Meaning | Common causes | Recommended client behavior |
|---|---|---|---|
| 200 | OK | — | Process `data` |
| 201 | Created | — | Process `data` |
| 202 | Accepted | Long-running write queued | Poll the resource until `status` settles (or, in v0.2+, watch the operation) |
| 204 | No Content | DELETE success | None |
| 401 | Unauthenticated | Missing/invalid token | Re-issue token, set `XCLOUD_API_TOKEN`, retry |
| 402 | Payment Required | Plan limit reached | Surface message to user; do not retry |
| 403 | Forbidden | Token scope missing OR `apiAccess` policy denies | Stop. Check scope + team role + permission. Do not retry |
| 404 | Not Found | UUID wrong, resource deleted, or scan never run | If "scan never run," trigger scan endpoint then retry |
| 422 | Unprocessable Entity | Validation failure | Read `errors[]` per field, fix input, retry |
| 429 | Too Many Requests | Rate limit (default 60 req/min) | Honor `Retry-After` header; back off exponentially |
| 5xx | Server error | Transient | Retry with exponential backoff (max 3 attempts) |

## Retry policy for agents

- **Never retry on 4xx except 429.** A 4xx means the request is wrong; retrying produces the same error.
- **Always retry 5xx** with exponential backoff: 1s, 2s, 4s. Cap at 3 attempts.
- **On 429**, read `Retry-After` (seconds) and wait that long before retrying.

## Pagination errors

If `?per_page` exceeds 100, the API clamps silently to 100 — no error. If `?page` exceeds `last_page`, the response is `200` with `items: []` and the original pagination block.

## Empty-state vs not-found

| Endpoint | Empty data state | Never-run state |
|---|---|---|
| `/sites/{uuid}/wordpress/plugins` | `200` with `items: []` | n/a (every WP site has plugins) |
| `/sites/{uuid}/wordpress/updates` | `200` with all counts at 0 | n/a |
| `/sites/{uuid}/wordpress/status` | `200` with nullable fields | n/a |
| `/sites/{uuid}/pagespeed` (v0.3) | n/a | `404` "No PageSpeed data — trigger a scan first." |
| `/sites/{uuid}/vulnerabilities` (v0.2) | `200` with `items: []` | `404` "No vulnerability data — trigger a scan first." |

## What to do on 403

403 from xCloud means one of:

1. The personal access token does not have the required scope (`read:sites`, etc.)
2. The user behind the token is not on the team that owns the resource
3. The user's team role is not `TEAM_ADMIN` / `SERVER_ADMIN` / `SITE_ADMIN`
4. The user is missing the specific team permission for that endpoint (e.g. `site:manage-update`)

The response body usually identifies which case. If not, ask the user to verify in **Profile → API Tokens** and **Team → Members**.
