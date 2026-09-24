
# xCloud SSL

Owns every SSL/certificate operation in the xCloud Public API. For auth, base
URL, the response envelope, pagination, and rate limits, read the shared layer
first — this skill does not repeat it:

- `reference/auth.md`
- `reference/conventions.md`
- `reference/mcp.md` — **prefer the MCP tools when
  connected**: `sites_ssl`, `sites_sslCertificates`, `sites_sslCertificates_create`,
  `sites_ssl_renew`, `ssl-certificates_show`, `ssl-certificates_status`,
  `ssl-certificates_destroy`; the `$XC` calls
  below are read-only REST fallbacks (`GET` only); changes run on the MCP.

All calls go through the shared wrapper:

```bash
XC="scripts/xcloud.sh"
```

Set `XCLOUD_API_BASE_URL=http://xcloud.test` (plus
`XCLOUD_ALLOW_INSECURE_HTTP=1` — plaintext http is refused without it) for
local, unset (or
`https://app.xcloud.host`) for live.

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · SSL** — <site domain>`, give the
trimmed result, and close with a `_via xcloud:ssl_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is renewing the SSL certificate for
\`<domain>\`…`; the first call of a task opens with
`☁️ xCloud is starting a session…`. **Every progress line and every action
sentence must start with `xCloud` as the actor — never a bare verb like
"Renewing…" or "Checking…". Say `xCloud is renewing…`.**

On the **first** xcloud reply in a conversation, lead with the xCloud startup
banner (see `reference/conventions.md` → **Startup banner**) in a fenced code
block — once per conversation.

## What this skill owns

| Operation | Method + path | Scope |
|---|---|---|
| Get site SSL info | `GET /sites/{uuid}/ssl` | `read:sites` |
| List site certificates | `GET /sites/{uuid}/ssl-certificates` | `read:sites` |
| Install a certificate | `POST /sites/{uuid}/ssl-certificates` | `write:sites` |
| Renew a certificate | `POST /sites/{uuid}/ssl/renew` | `write:sites` + `site:manage-ssl` |
| Get certificate by UUID | `GET /ssl-certificates/{uuid}` | `read:sites` |
| Get certificate status | `GET /ssl-certificates/{uuid}/status` | `read:sites` |
| Delete a certificate | `DELETE /ssl-certificates/{uuid}` | `write:sites` |

**Not here:** site backups/domains/cache/SSH → `xcloud:sites`; WordPress plugin
vulnerabilities → `xcloud:wordpress`; server firewall/fail2ban → `xcloud:servers`.

## Workflow

1. Resolve the site UUID first (via `xcloud:sites`: `GET /sites?search=<domain>`).
2. Inspect current SSL before changing it.
3. Installs/renewals are async — poll certificate status afterward.

## Reads

Current SSL state for a site:

```bash
SITE_UUID='replace-me'
"$XC" GET "/sites/$SITE_UUID/ssl" | jq '.data'
```

List a site's certificates:

```bash
"$XC" GET "/sites/$SITE_UUID/ssl-certificates" \
  | jq '(.data.items // .data.data // .data) | map({uuid, provider, status, domains, expires_at})'
```

Certificate detail / status by UUID:

```bash
CERT_UUID='replace-me'
"$XC" GET "/ssl-certificates/$CERT_UUID" | jq '.data'
"$XC" GET "/ssl-certificates/$CERT_UUID/status" | jq '.data'
```

## Changes (MCP)

Installs, renewals and deletions run on the MCP tools below; the REST wrapper is
read-only. Without MCP, offer to connect it (`reference/conventions.md` →
Transports). Every call here is destructive-class — restate the domain and the
effect, get the yes, then send `confirm: true`.

```text
# Let's Encrypt via xCloud
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "xcloud"}  # destructive: confirm: true after the user's yes
# the team's Cloudflare integration
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "cloudflare"}  # destructive: confirm: true after the user's yes
# switch providers when one is already configured — force is required
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "cloudflare", "force": true}  # destructive: confirm: true after the user's yes
# WordPress site adopting HTTPS for the first time — DB search-replace
sites_sslCertificates_create  {"uuid": "<site-uuid>", "provider": "xcloud", "ssl_search_replace": true}  # destructive: confirm: true after the user's yes
# renew — a no-op unless the cert expires within 7 days, unless forced
sites_ssl_renew               {"uuid": "<site-uuid>"}  # destructive: confirm: true after the user's yes
sites_ssl_renew               {"uuid": "<site-uuid>", "force": true}  # destructive: confirm: true after the user's yes
# delete a certificate
ssl-certificates_destroy      {"uuid": "<certificate-uuid>"}  # destructive: confirm: true after the user's yes
```

A custom certificate needs `provider: "custom"` with the PEM `certificate` and
`private_key`. The private key is a secret: read both from the files the user
points to, pass them only as tool arguments, and never paste the key into the
chat or echo it back.

## Request notes (from the spec)

- `provider` ∈ `xcloud` | `custom` | `cloudflare` (required on install).
- `provider=custom` requires both `certificate` and `private_key` (PEM).
- `force: true` is required only to switch to a *different* provider; ignored
  when none is set or the provider matches.
- `ssl_search_replace` applies to WordPress sites only; silently ignored
  elsewhere.
- Renew without `force` is a no-op unless the cert is within 7 days of expiry.

## Pitfalls

- `403` on renew with a valid token = missing `site:manage-ssl` team permission.
- Private key material is never returned by reads — do not expect it.
- Installs/renewals report success before issuance completes; confirm via
  `GET /ssl-certificates/{uuid}/status`.
