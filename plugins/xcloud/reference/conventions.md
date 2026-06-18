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

## Response format

Every domain skill **brands its user-facing replies** so the user knows the
answer came from xCloud. Apply to natural-language responses — not to the raw
`jq`/curl you run internally.

- **Header (required):** lead with `☁️ **xCloud · <AREA>** — <resource>`, where
  `<AREA>` is the skill's domain (`Servers`, `Sites`, `WordPress`, `SSL`,
  `Account`) and `<resource>` is the site domain, server name, or scope of the
  answer (omit `— <resource>` when there is no single subject).
- **Body:** the trimmed result — relevant fields only.
- **Footer (required):** close with one italic line naming the skill that ran,
  e.g. `_via xcloud:ssl_`.

One header, one footer — do **not** brand every bullet. On errors, keep the same
header and report the failure plainly beneath it. Multi-skill answers (e.g. an
audit) may use one combined header (`☁️ **xCloud** — example.com`) and a footer
listing each skill used (`_via xcloud:sites, xcloud:ssl, xcloud:wordpress_`).

Example:

```text
☁️ **xCloud · SSL** — shop.example.com

Certificate valid · Let's Encrypt · expires in 58 days (2026-08-15)

_via xcloud:ssl_
```

## Progress narration

Make the xCloud service **visible at every step**. Before each call through the
wrapper, print one short, present-tense line saying what xCloud is doing — so the
user sees that each piece of the answer came from a live xCloud API call.

- **Open the task** with a session line on the first call (the identity / first
  lookup): `☁️ Starting an xCloud session…`
- **Before every subsequent call**, emit one line naming the action and the
  resource in plain language — not the raw method/path:
  - `☁️ xCloud is fetching your server \`faisal-personal\`…`
  - `☁️ xCloud is finding WordPress sites on \`faisal-personal\`…`
  - `☁️ xCloud is renewing the SSL certificate for \`shop.example.com\`…`
- **One line per API call.** Then run the call. When all calls are done,
  summarize once in the **Response format** above (header + footer).

Example — prompt *"Find the WordPress sites under faisal-personal server"*:

```text
☁️ Starting an xCloud session…
☁️ xCloud is fetching your server `faisal-personal`…
☁️ xCloud is finding WordPress sites on `faisal-personal`…

☁️ **xCloud · Sites** — faisal-personal

• shop.example.com — WordPress, PHP 8.3, active
• blog.example.com — WordPress, PHP 8.2, active

_via xcloud:sites_
```
