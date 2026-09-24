
# xCloud WordPress

Owns WordPress app management plus site vulnerability scanning, PageSpeed, and
broken-link scans.
Read the shared layer first for auth, base URL, and conventions:

- `reference/auth.md`
- `reference/conventions.md`
- `reference/mcp.md` — **prefer the MCP tools when
  connected**: `sites_wordpress_*` (plugins/themes/updates/status/update/
  activate/refresh), `sites_vulnerabilities_*`, `vulnerabilities_index`
  (team-wide), `sites_pagespeed_*`, `sites_broken-links_*`, `sites_wp-debug`,
  `sites_magic-login`;
  the `$XC` calls
  below are read-only REST fallbacks (`GET` only); changes run on the MCP.

```bash
XC="scripts/xcloud.sh"
```

Scopes: reads need `read:sites`, writes need `write:sites`.

## Response format

Brand every user-facing reply (see `reference/conventions.md` →
**Response format**): open with `☁️ **xCloud · WordPress** — <site domain>`, give
the trimmed result, and close with a `_via xcloud:wordpress_` line.

Narrate each call (see **Progress narration**): before every `$XC` call print one
line of what xCloud is doing, e.g. `☁️ xCloud is scanning \`<domain>\` for
vulnerabilities…`; the first call of a task opens with
`☁️ xCloud is starting a session…`. **Every progress line and every action
sentence must start with `xCloud` as the actor — never a bare verb like
"Scanning…" or "Updating…". Say `xCloud is scanning…`.**

On the **first** xcloud reply in a conversation, lead with the xCloud startup
banner (see `reference/conventions.md` → **Startup banner**) in a fenced code
block — once per conversation.

## Sub-resources (load on demand)

| Sub-resource | Reference file |
|---|---|
| Plugins, themes, updates, activate, refresh | `reference/wordpress-plugins-themes.md` |
| Vulnerabilities (scan, list, ignore) | `reference/wordpress-vulnerabilities.md` |
| PageSpeed Insights | `reference/wordpress-pagespeed.md` |
| Broken links (scan, poll, findings) | `reference/wordpress-broken-links.md` |

## Core endpoints

| Operation | Method + path |
|---|---|
| WP health status | `GET /sites/{uuid}/wordpress/status` |
| Updates summary | `GET /sites/{uuid}/wordpress/updates` |
| Toggle WP_DEBUG | `POST /sites/{uuid}/wp-debug` |
| Magic login URL | `POST /sites/{uuid}/magic-login` |

**Not here:** SSL → `xcloud:ssl`; backups/domains/cache/SSH → `xcloud:sites`;
server infra → `xcloud:servers`.

## Examples

WordPress health + pending updates:

```bash
SITE_UUID='replace-me'
"$XC" GET "/sites/$SITE_UUID/wordpress/status"  | jq '.data'
"$XC" GET "/sites/$SITE_UUID/wordpress/updates" | jq '.data'
```

Toggle WP_DEBUG (`enabled` required; MCP — the REST wrapper is read-only):

```text
sites_wp-debug  {"uuid": "<site-uuid>", "enabled": true}  # destructive: confirm: true after the user's yes
```

Generate a one-time admin magic-login URL (MCP; the first call installs the
magic-login plugin over SSH):

```text
sites_magic-login  {"uuid": "<site-uuid>", "login_as": "admin"}  # destructive: confirm: true after the user's yes
```

## Fleet questions

"Which of my sites have pending core, plugin or theme updates?" → list sites
(`xcloud:sites`), keep the WordPress ones, read each one's updates summary, and
answer grouped by site with counts; offer to update the ones the user picks
(back up first — `reference/wordpress-plugins-themes.md`). For vulnerabilities across the
team, `GET /vulnerabilities` answers in one call — sort worst first.

## Cross-domain note

`vulnerabilities` and `pagespeed` are addressed at `/sites/{uuid}/…` and work on
any site, but are owned here because they are predominantly WordPress concerns.
A non-WordPress "scan my site" request still routes here via the `xcloud:sites`
cross-link.

## Pitfalls

- Plugin/theme updates and activations are async and can optionally back up
  first — see `reference/wordpress-plugins-themes.md`.
- Magic-login URLs are single-use and expire after about ten minutes; treat them
  like passwords, never log them. The first call on a site installs the
  magic-login plugin over SSH, which is why it is confirm-gated on MCP.
