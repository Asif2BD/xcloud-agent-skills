# API conventions (shared)

Shared by every `xcloud-*` domain skill. Read this once; the domain skills do not
repeat it.

## Response envelope

Every response uses:

```json
{ "success": true, "message": "Success", "data": {} }
```

On error, `success: false` and `message` carries the reason; HTTP status is the
authority (`401` auth, `403` permission, `404` not found, `422` validation,
`429` rate limit).

## Pagination (two shapes)

List endpoints return **either** shape — inspect before assuming:

- `data.items` + `data.pagination`  (most live endpoints)
- `data.data` + `data.meta`         (some docs examples)

Shape-tolerant jq:

```bash
jq '(.data.items // .data.data // [])'
jq '.data.pagination // .data.meta'
```

## Resource identifiers

- Servers, sites, SSL certificates, sudo users: `{uuid}`.
- User token revocation: numeric `{tokenId}`.
- Resolve a UUID with a read endpoint before any write.

## Rate limits

- Authenticated: 60 req/min. Unauthenticated: 10 req/min.
- `429` returns `Retry-After`; honor it.

## Async writes

Writes often return `success` immediately while work continues. Poll a read
endpoint (status/events/tasks) to confirm completion.

## Operating style

- Read first to resolve UUIDs; restate the target resource before any
  state-changing call.
- Trim output with `jq`; return the relevant fields, not raw noise.
- The shared wrapper is `"${CLAUDE_PLUGIN_ROOT}"/scripts/xcloud.sh`.
